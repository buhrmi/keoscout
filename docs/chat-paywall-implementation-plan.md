# Chat + DMs + Paywalled Posts — Implementation Plan

## Overview

Add real-time chat/DMs with offline support, media uploads to Bunny CDN, and a "promote to paywalled post" feature. Media is stored once on Bunny and referenced by both chat messages and posts.

---

## Architecture Summary

```
┌──────────────────────────────────────────────────┐
│                    Bunny CDN                       │
│  ┌──────────────┐  ┌───────────────────────────┐  │
│  │ Storage Zone  │  │     Stream Library        │  │
│  │  (images)     │  │  (videos, transcoded)     │  │
│  └──────┬───────┘  └──────────┬────────────────┘  │
│         │                     │                    │
│  ┌──────┴─────────────────────┴────────────────┐  │
│  │    Pull Zone (cdn.keoscout.com)              │  │
│  │    • Token-protected originals               │  │
│  │    • Public blurred previews                 │  │
│  └──────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
         ▲                              ▲
         │ Reference URLs               │
         │                              │
   ┌─────┴──────┐              ┌───────┴──────┐
   │  Message    │   promote    │    Post       │
   │  (chat DM)  │──────────────│  (paywalled)  │
   └─────┬──────┘              └───────┬──────┘
         │                            │
         ▼                            ▼
   Action Cable               Token-gated view
   (SolidCable)               (PostPurchase check)
         │
         ▼
   IndexedDB (Dexie.js)
   ┌─────────────────────┐
   │ Offline queue        │
   │ Pending messages     │
   │ Cached conversations │
   └─────────────────────┘
```

---

## Phase 1: Foundation — Models & Migrations

### 1.1 Database Migrations

#### `CreateConversations`

```ruby
create_table :conversations do |t|
  t.string :conversation_type, null: false  # "dm" or "group"
  t.string :title                          # for group chats
  t.timestamps
end
```

#### `CreateConversationParticipants`

```ruby
create_table :conversation_participants do |t|
  t.references :user, null: false
  t.references :conversation, null: false
  t.datetime :last_read_at
  t.timestamps
end

add_index :conversation_participants, [:user_id, :conversation_id], unique: true
```

#### `CreateMessages`

```ruby
create_table :messages do |t|
  t.references :conversation, null: false
  t.references :user, null: false
  t.text :content                           # nullable — for media-only messages
  t.json :attachments, default: []          # array of attachment objects
  t.datetime :created_at, null: false
end

add_index :messages, [:conversation_id, :created_at]
```

#### `CreatePosts`

```ruby
create_table :posts do |t|
  t.references :user, null: false
  t.string :title
  t.text :description
  t.json :media_urls, default: []           # same structure as message attachments
  t.references :source_message,             # which chat message this came from
               foreign_key: { to_table: :messages }, null: true
  t.boolean :paywalled, default: false
  t.decimal :price_usd, precision: 10, scale: 2
  t.timestamps
end
```

#### `CreatePostPurchases`

```ruby
create_table :post_purchases do |t|
  t.references :user, null: false
  t.references :post, null: false
  t.string :tx_signature                   # Solana transaction signature
  t.timestamps
end

add_index :post_purchases, [:user_id, :post_id], unique: true
```

### 1.2 Models

```ruby
# app/models/conversation.rb
class Conversation < ApplicationRecord
  has_many :participants, class_name: "ConversationParticipant"
  has_many :users, through: :participants
  has_many :messages, -> { order(created_at: :asc) }

  def self.between(user1, user2)
    dm = where(conversation_type: "dm")
         .joins(:participants)
         .where(conversation_participants: { user_id: [user1.id, user2.id] })
         .group(:id)
         .having("COUNT(*) = 2")
         .first
  end
end

# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  has_one :promoted_post, class_name: "Post",
          foreign_key: :source_message_id, dependent: :nullify

  after_create_commit :broadcast_message

  def attachment_urls_for_client
    attachments.map { |a| a.slice("blurred_url", "thumbnail_url", "type") }
  end

  def signed_attachment_urls
    # Replaced with signed Bunny URLs after payment verification
  end

  private

  def broadcast_message
    broadcast_append_to(
      conversation,
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
    )
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :source_message, class_name: "Message", optional: true
  has_many :purchases, class_name: "PostPurchase"

  def paid_by?(user)
    return false unless user
    return true if user == self.user  # creator always has access
    purchases.exists?(user_id: user.id)
  end

  def signed_media_urls(expires_in: 1.hour)
    # Generate Bunny token-authenticated URLs
  end
end
```

---

## Phase 2: Real-Time Chat (Action Cable)

### 2.1 Channel

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    conversation = Current.user.conversations.find(params[:conversation_id])
    stream_for conversation
  end

  def speak(data)
    conversation = Current.user.conversations.find(data["conversation_id"])
    message = conversation.messages.create!(
      user: Current.user,
      content: data["content"],
      attachments: data["attachments"] || []
    )
    # after_create_commit broadcasts automatically
  end

  def read(data)
    participant = Current.user.participants
                    .find_by!(conversation_id: data["conversation_id"])
    participant.update!(last_read_at: Time.current)
  end
end
```

### 2.2 Controllers (Inertia)

```ruby
# app/controllers/dashboard/conversations_controller.rb
module Dashboard
  class ConversationsController < BaseController
    def index
      @conversations = Current.user.conversations
        .includes(:users, messages: :user)
        .order(updated_at: :desc)
    end

    def show
      @conversation = Current.user.conversations.find(params[:id])
      @messages = @conversation.messages.includes(:user).page(params[:page])
    end

    def create
      # Find or create DM between current_user and recipient
      recipient = User.find(params[:user_id])
      @conversation = Conversation.between(Current.user, recipient) ||
                      Conversation.create_dm(Current.user, recipient)
    end
  end
end
```

### 2.3 Action Cable Client (Svelte)

```js
// app/frontend/lib/cable.ts
import { createConsumer } from "@rails/actioncable"

let consumer: ReturnType<typeof createConsumer> | null = null

export function getConsumer() {
  if (!consumer) {
    consumer = createConsumer("/cable")
  }
  return consumer
}
```

---

## Phase 3: Offline Support (IndexedDB + Dexie.js)

### 3.1 New Dependencies

```bash
npm add dexie @rails/actioncable
```

### 3.2 Dexie Schema

```ts
// app/frontend/lib/db.ts
import Dexie, { type EntityTable } from "dexie"

interface CachedMessage {
  id: number | string        // server ID or local UUID for pending
  conversationId: number
  userId: number
  content: string | null
  attachmentUrls: Array<{
    blurredUrl: string
    originalKey: string
    type: "image" | "video"
  }>
  status: "pending" | "sent" | "failed"
  pendingAttachments?: Array<{
    localBlob: Blob
    type: string
  }>
  createdAt: Date
}

interface CachedConversation {
  id: number
  type: "dm" | "group"
  lastMessage: string | null
  lastActivityAt: Date
}

const db = new Dexie("keoscout_chat") as Dexie & {
  messages: EntityTable<CachedMessage, "id">
  conversations: EntityTable<CachedConversation, "id">
}

db.version(1).stores({
  messages: "id, conversationId, status, createdAt",
  conversations: "id, lastActivityAt",
})

export { db }
export type { CachedMessage, CachedConversation }
```

### 3.3 Svelte Rune Store

```ts
// app/frontend/stores/chat.svelte.ts
import { db, type CachedMessage } from "~/lib/db"
import { getConsumer } from "~/lib/cable"

class ChatStore {
  conversations = $state<Map<number, CachedMessage[]>>(new Map())
  online = $state(navigator.onLine)
  private pendingSync = $state<Set<string>>(new Set())

  constructor() {
    // Monitor network status
    window.addEventListener("online", () => this.syncPending())
    window.addEventListener("offline", () => this.online = false)
  }

  // Load conversation from IndexedDB first, then sync from server
  async loadConversation(id: number) {
    const cached = await db.messages
      .where("conversationId").equals(id)
      .sortBy("createdAt")
    
    this.conversations.set(id, cached)
    
    // Subscribe to Action Cable
    getConsumer().subscriptions.create(
      { channel: "ChatChannel", conversation_id: id },
      {
        received: (data: CachedMessage) => this.handleIncoming(data),
      }
    )
  }

  // Send message (optimistic)
  async sendMessage(conversationId: number, content: string, files?: File[]) {
    const localId = crypto.randomUUID()
    const message: CachedMessage = {
      id: localId,
      conversationId,
      userId: getCurrentUserId(),
      content,
      attachmentUrls: [],
      status: this.online ? "pending" : "pending",
      createdAt: new Date(),
      pendingAttachments: files?.map(f => ({ localBlob: f, type: f.type })),
    }
    
    // Optimistic insert
    await db.messages.add(message)
    this.upsertMessage(conversationId, message)

    if (this.online) {
      // Upload files to Bunny first, then send message
      await this.uploadAndSend(message)
    } else {
      this.pendingSync.add(localId as string)
    }
  }

  private async uploadAndSend(message: CachedMessage) {
    // 1. Upload files to Bunny (see Phase 4)
    // 2. POST to Rails /messages
    // 3. Update status to "sent"
  }

  private async syncPending() {
    this.online = true
    for (const localId of this.pendingSync) {
      const msg = await db.messages.get(localId)
      if (msg) await this.uploadAndSend(msg)
    }
    this.pendingSync.clear()
  }

  private handleIncoming(message: CachedMessage) {
    db.messages.put(message)
    this.upsertMessage(message.conversationId, message)
  }

  private upsertMessage(convId: number, msg: CachedMessage) {
    const msgs = this.conversations.get(convId) || []
    const idx = msgs.findIndex(m => m.id === msg.id)
    if (idx >= 0) msgs[idx] = msg
    else msgs.push(msg)
    this.conversations.set(convId, [...msgs].sort((a, b) =>
      +new Date(a.createdAt) - +new Date(b.createdAt)
    ))
  }
}

export const chatStore = new ChatStore()
```

### 3.4 Offline Strategy Summary

| Layer | Mechanism |
|---|---|
| **Read messages offline** | IndexedDB mirrors server state — conversations load from local cache first |
| **Send messages offline** | Queued in IndexedDB with `status: pending`, synced on reconnect |
| **Reconnect sync** | `navigator.onLine` listener + manual retry on failure |
| **App shell offline** | PWA Service Worker (already scaffolded) caches app shell |
| **Ordering** | Messages sorted by `createdAt` from server timestamp; pending messages get server timestamp on sync, then re-sorted |

---

## Phase 4: Bunny CDN Uploads

### 4.1 Bunny Setup Checklist

- [ ] Create **Bunny Storage Zone** (S3-compatible, region: nearest)
  - [ ] Set password for authenticated access
  - [ ] Note: API key + Storage Zone name + password
- [ ] Create **Bunny Stream Library** (for video transcoding)
  - [ ] Note: Library ID + API key
- [ ] Create **Pull Zone** pointed at Storage Zone
  - [ ] Enable **Token Authentication** (generate signing key)
  - [ ] Set custom hostname (e.g., `cdn.keoscout.com`)
- [ ] Add credentials to Rails: `rails credentials:edit`

```yaml
bunny:
  storage:
    api_key: "xxx"
    zone_name: "keoscout-media"
    password: "xxx"
    base_url: "https://storage.bunnycdn.com"
    cdn_url: "https://cdn.keoscout.com"
    token_key: "xxx"           # Pull Zone token signing key
  stream:
    api_key: "xxx"
    library_id: "12345"
```

### 4.2 Rails Upload Service

```ruby
# app/services/bunny_upload_service.rb
class BunnyUploadService
  BUNNY_STORAGE_URL = Rails.application.credentials.bunny.storage.base_url
  ZONE_NAME = Rails.application.credentials.bunny.storage.zone_name
  PASSWORD = Rails.application.credentials.bunny.storage.password

  class Error < StandardError; end

  def self.generate_signed_upload_url(filename:, content_type:, user_id:)
    path = "uploads/#{user_id}/#{SecureRandom.uuid}/#{filename}"
    expiry = (Time.now + 30.minutes).to_i

    url = "#{BUNNY_STORAGE_URL}/#{ZONE_NAME}/#{path}"
    
    # Bunny Storage uses AccessKey auth header
    # Return the URL + headers needed for direct upload
    {
      upload_url: url,
      public_cdn_url: "#{cdn_base_url}/#{path}",
      headers: {
        "AccessKey" => PASSWORD,
        "Content-Type" => content_type,
      },
      path: path,
      expires_at: expiry,
    }
  end

  def self.generate_blurred_filename(original_path)
    dir = File.dirname(original_path)
    ext = File.extname(original_path)
    base = File.basename(original_path, ext)
    "#{dir}/blurred_#{base}.jpg"
  end

  def self.cdn_base_url
    Rails.application.credentials.bunny.storage.cdn_url
  end

  # Bunny Stream: Create video and return upload URL
  def self.create_video(title:, user_id:)
    library_id = Rails.application.credentials.bunny.stream.library_id
    api_key = Rails.application.credentials.bunny.stream.api_key

    response = HTTParty.post(
      "https://video.bunnycdn.com/library/#{library_id}/videos",
      headers: {
        "AccessKey" => api_key,
        "Content-Type" => "application/json",
      },
      body: { title: title }.to_json
    )

    raise Error, "Failed to create video: #{response.body}" unless response.success?

    data = JSON.parse(response.body)
    {
      video_id: data["guid"],
      upload_url: nil,  # Fetch upload URL separately
    }
  end
end
```

### 4.3 Server-Side Blurring

```ruby
# app/services/media_blur_service.rb
class MediaBlurService
  require "image_processing/mini_magick"

  # Destructively blur so the original cannot be recovered
  def self.blur_image(source_path)
    processed = ImageProcessing::MiniMagick
      .source(source_path)
      .resize_to_limit(400, 400)       # Downscale → information loss
      .blur("0x50")                    # Gaussian blur σ=50
      .quality(10)                     # Heavy JPEG compression
      .call

    output_path = BunnyUploadService.generate_blurred_filename(source_path)
    # Upload processed result to Bunny as public file
    upload_blurred(processed.path, output_path)

    output_path
  end

  def self.blur_video_frame(video_id)
    # Bunny Stream generates thumbnails automatically.
    # Grab the generated thumbnail, blur it, and re-upload as preview.
    # Never serve a blurred video stream — motion leaks information.
    library_id = Rails.application.credentials.bunny.stream.library_id
    thumbnail_url = "https://#{library_id}.b-cdn.net/#{video_id}/thumbnail.jpg"
    
    tempfile = Down.download(thumbnail_url)
    blur_image(tempfile.path)
  end

  def self.upload_blurred(file_path, destination_path)
    url = "#{BunnyUploadService::BUNNY_STORAGE_URL}/#{BunnyUploadService::ZONE_NAME}/#{destination_path}"
    HTTParty.put(
      url,
      headers: {
        "AccessKey" => BunnyUploadService::PASSWORD,
        "Content-Type" => "image/jpeg",
      },
      body: File.binread(file_path),
    )
  end
end
```

### 4.4 Client-Side Upload Endpoint

```ruby
# app/controllers/uploads_controller.rb
class UploadsController < ApplicationController
  before_action :require_authentication

  def sign
    result = BunnyUploadService.generate_signed_upload_url(
      filename: params[:filename],
      content_type: params[:content_type],
      user_id: Current.user.id,
    )

    render json: {
      upload_url: result[:upload_url],
      public_cdn_url: result[:public_cdn_url],
      headers: result[:headers],
      blurred_key: BunnyUploadService.generate_blurred_filename(result[:path]),
    }
  end

  # Called after client finishes uploading to Bunny
  def complete
    # 1. Fetch the uploaded file from Bunny
    # 2. Generate blurred version server-side
    # 3. Upload blurred version back to Bunny (public)
    # 4. Return both URLs

    blurred_path = MediaBlurService.blur_image_via_bunny(params[:original_key])

    render json: {
      original_key: params[:original_key],
      blurred_url: "#{BunnyUploadService.cdn_base_url}/#{blurred_path}",
    }
  end
end
```

### 4.5 Upload Flow (Svelte Side)

```ts
// app/frontend/lib/upload.ts
interface UploadResult {
  originalKey: string
  blurredUrl: string
  type: "image" | "video"
  thumbnailUrl: string
}

async function uploadFile(file: File): Promise<UploadResult> {
  // 1. Get signed URL from Rails
  const signResp = await fetch("/uploads/sign", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      filename: file.name,
      content_type: file.type,
    }),
  })
  const { upload_url, public_cdn_url, headers, blurred_key } = await signResp.json()

  // 2. Upload directly to Bunny
  await fetch(upload_url, {
    method: "PUT",
    headers: { ...headers },
    body: file,
  })

  // 3. Tell Rails to generate blurred version
  const completeResp = await fetch("/uploads/complete", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ original_key: public_cdn_url }),
  })
  const { original_key, blurred_url } = await completeResp.json()

  return {
    originalKey: original_key,
    blurredUrl: blurred_url,
    type: file.type.startsWith("video/") ? "video" : "image",
    thumbnailUrl: blurred_url,
  }
}

export { uploadFile }
export type { UploadResult }
```

---

## Phase 5: "Promote to Post" Feature

### 5.1 Backend

Add to `Dashboard::PostsController`:

```ruby
# POST /dashboard/posts
def create
  @post = Current.user.posts.create!(
    title: params[:title],
    description: params[:description],
    media_urls: params[:media_urls],         # Same URLs from the message
    source_message_id: params[:source_message_id],
    paywalled: params[:paywalled] || false,
    price_usd: params[:price_usd],
  )

  redirect_to dashboard_post_path(@post)
end

# GET /dashboard/posts/:id
def show
  @post = Post.find(params[:id])

  if @post.paywalled? && !@post.paid_by?(Current.user)
    # Show blurred version — media URLs are the public blurred urls
    render "posts/show_blurred"
  else
    # Generate signed Bunny URLs for full access (1-hour expiry)
    @media_urls = @post.signed_media_urls(expires_in: 1.hour)
    render "posts/show"
  end
end
```

### 5.2 Post Model — Token Signing

```ruby
# app/models/post.rb (addition)
def signed_media_urls(expires_in: 1.hour)
  token_key = Rails.application.credentials.bunny.storage.token_key
  return media_urls if token_key.blank?  # fallback for dev

  expires = (Time.now + expires_in).to_i

  media_urls.map do |media|
    url = "#{BunnyUploadService.cdn_base_url}/#{media["original_key"]}"
    token = BunnyTokenSigner.sign(url: url, expires: expires, key: token_key)
    media.merge("url" => "#{url}?token=#{token}")
  end
end

# app/services/bunny_token_signer.rb
class BunnyTokenSigner
  def self.sign(url:, expires:, key:)
    # Bunny token auth uses: MD5(key + path + expires) or SHA256 depending on zone config
    uri = URI.parse(url)
    path = uri.path
    token_string = "#{key}#{path}#{expires}"
    token = Digest::SHA256.hexdigest(token_string)
    "expires=#{expires}&token_signature=#{token}"
  end
end
```

### 5.3 Svelte — "Create Post" Action on Chat Media

```svelte
<!-- In chat message bubble, for messages with attachments -->
{#if message.attachments?.length > 0}
  <div class="message-media">
    {#each message.attachments as attachment}
      <img src={attachment.blurredUrl} alt="Chat media" />
      <button
        class="promote-btn"
        onclick={() => promoteToPost(message)}
      >
        💰 Create Paywalled Post
      </button>
    {/each}
  </div>
{/if}
```

---

## Phase 6: Paywall Enforcement

### 6.1 Payment Flow

```
Viewer clicks "Unlock for $4.99"
         │
         ▼
  Solana transaction via Reown AppKit (already integrated)
         │
         ▼
  Frontend sends tx signature to Rails
         │
         ▼
  POST /dashboard/posts/:id/purchase
  { tx_signature: "..." }
         │
         ▼
  Rails verifies transaction on-chain (optional for MVP, trusted for now)
         │
         ▼
  Creates PostPurchase record
         │
         ▼
  Returns signed Bunny URLs → full content renders
```

### 6.2 Purchase Controller

```ruby
# app/controllers/dashboard/purchases_controller.rb
module Dashboard
  class PurchasesController < BaseController
    def create
      @post = Post.find(params[:post_id])
      
      purchase = @post.purchases.create!(
        user: Current.user,
        tx_signature: params[:tx_signature],
      )

      render json: {
        success: true,
        media_urls: @post.signed_media_urls,
      }
    end
  end
end
```

### 6.3 Routes

```ruby
# config/routes.rb additions
namespace :dashboard do
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:index, :create]
  end
  resources :posts do
    resource :purchase, only: [:create], module: :dashboard
  end
end

resources :uploads, only: [] do
  collection do
    post :sign
    post :complete
  end
end
```

---

## Phase 7: PWA Service Worker for Offline Shell

Enable the already-scaffolded PWA routes in `config/routes.rb`:

```ruby
get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
```

The default Rails PWA service worker will cache the app shell. Add a cache strategy for media:

```js
// public/service-worker.js (extend the Rails-generated one)
self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url)
  
  // Cache Bunny CDN media
  if (url.hostname === "cdn.keoscout.com") {
    event.respondWith(
      caches.match(event.request).then((cached) => {
        const fetchPromise = fetch(event.request).then((response) => {
          caches.open("keoscout-media").then((cache) => {
            cache.put(event.request, response.clone())
          })
          return response
        })
        return cached || fetchPromise
      })
    )
  }
})
```

---

## File Tree Summary

```
New/modified files:

app/
  models/
    conversation.rb              # NEW
    conversation_participant.rb   # NEW
    message.rb                    # NEW
    post.rb                       # NEW
    post_purchase.rb              # NEW
  controllers/
    application_controller.rb     # MODIFY — add Current.user setup
    uploads_controller.rb         # NEW
    dashboard/
      conversations_controller.rb # NEW
      messages_controller.rb      # NEW
      posts_controller.rb         # MODIFY — add create/show/purchase
      purchases_controller.rb     # NEW
  channels/
    chat_channel.rb               # NEW
  services/
    bunny_upload_service.rb       # NEW
    media_blur_service.rb         # NEW
    bunny_token_signer.rb         # NEW
  frontend/
    lib/
      cable.ts                    # NEW — Action Cable client
      db.ts                       # NEW — Dexie.js setup
      upload.ts                   # NEW — Bunny direct upload
    stores/
      chat.svelte.ts              # NEW — Chat rune store
    pages/
      dashboard/
        conversations/
          index.svelte            # NEW
          show.svelte             # NEW
        posts/
          show.svelte             # MODIFY — paywall logic
          new.svelte              # MODIFY — post composer

config/
  routes.rb                       # MODIFY — add chat/post/upload routes

db/
  migrate/
    xxx_create_conversations.rb
    xxx_create_messages.rb
    xxx_create_posts.rb
    xxx_create_post_purchases.rb

package.json                      # MODIFY — add dexie, @rails/actioncable
```

---

## Implementation Order

| Priority | Phase | Why |
|---|---|---|
| 1 | Phase 1 — Models & Migrations | Everything depends on the data layer |
| 2 | Phase 2 — Action Cable Chat | Core feature, can work without offline/media |
| 3 | Phase 4 — Bunny Uploads | Media is needed before Phase 5 |
| 4 | Phase 3 — Offline (Dexie) | Add offline after core chat works |
| 5 | Phase 5 — Promote to Post | Depends on media being stored |
| 6 | Phase 6 — Paywall | Depends on posts existing |
| 7 | Phase 7 — PWA | Polish; can be done in parallel with Phase 5–6 |

---

## Key Design Decisions

1. **Media stored once, referenced twice** — No duplication between messages and posts. Both point to the same Bunny URLs.

2. **Blur is irreversible** — 400px downscale + σ=50 Gaussian blur + JPEG quality 10. Recovery is information-theoretically impossible, not just hard.

3. **Video preview is a single blurred frame** — Never serve a blurred video stream. Motion patterns in blurred video still leak information.

4. **Originals require token auth** — Bunny Zone Token Authentication means the original URL returns 403 unless signed. Rails only signs URLs after verifying payment.

5. **Optimistic chat with offline queue** — Messages appear instantly in UI, synced to server when connectivity allows. Pending messages stored in IndexedDB.

6. **IndexedDB as cache, not source of truth** — Server is authoritative. IndexedDB provides offline read access and pending write queue.
