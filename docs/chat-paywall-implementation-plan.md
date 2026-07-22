# Chat + DMs + Paywalled Posts — Implementation Plan (Stripe Edition)

## Overview

This document outlines the revised technical architecture and implementation roadmap for introducing real-time chat/DMs, offline media handling via Bunny CDN, Web Push notifications, and a "promote to paywalled post" feature. 

This updated plan removes Solana in favor of **Stripe** for fiat monetization (Checkout Sessions + Webhooks), optimizes client-side image blurring to preserve web server performance, tightens CDN token TTLs for better access control, and records full transaction history for accounting precision.

---

## Architecture Summary


```

┌──────────────────────────────────────────────────┐
│                    Bunny CDN                     │
│  ┌──────────────┐  ┌───────────────────────────┐  │
│  │ Storage Zone │  │     Stream Library        │  │
│  │  (images)    │  │  (videos, transcoded)     │  │
│  └──────┬───────┘  └──────────┬────────────────┘  │
│         │                     │                    │
│  ┌──────┴─────────────────────┴────────────────┐  │
│  │    Pull Zone (cdn.keoscout.com)              │  │
│  │    • Token-protected originals (15m TTL)     │  │
│  │    • Public blurred previews                 │  │
│  └──────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
▲                              ▲
│ Reference URLs               │
│                              │
┌─────┴──────┐              ┌───────┴──────┐
│  Message   │   promote    │    Post      │
│  (chat DM) │──────────────│  (paywalled) │
└─────┬──────┘              └───────┬──────┘
│                             │
▼                             ▼
Action Cable              Stripe Checkout Session
(SolidCable)                & Webhook Fulfillment
│                             │
▼                             ▼
IndexedDB (Dexie.js)        PostPurchase (verified)
┌─────────────────────┐
│ Offline queue       │
│ Pending messages    │
│ Cached conversations│
└─────────────────────┘

```


---

## Phase 1: Foundation — Models & Migrations

### 1.1 Database Migrations

#### `CreateConversations`
```ruby
# db/migrate/xxx_create_conversations.rb
class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.string :conversation_type, null: false, default: "dm" # "dm" or "group"
      t.string :title
      t.timestamps
    end
  end
end

```

#### `CreateConversationParticipants`

```ruby
# db/migrate/xxx_create_conversation_participants.rb
class CreateConversationParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_participants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.datetime :last_read_at
      t.timestamps
    end

    add_index :conversation_participants, [:user_id, :conversation_id], unique: true
  end
end

```

#### `CreateMessages`

```ruby
# db/migrate/xxx_create_messages.rb
class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content                           # nullable — for media-only messages
      t.json :attachments, default: []          # array of attachment objects
      t.timestamps
    end

    add_index :messages, [:conversation_id, :created_at]
  end
end

```

#### `CreatePosts`

```ruby
# db/migrate/xxx_create_posts.rb
class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.json :media_urls, default: []           # array of attachment objects
      t.references :source_message, foreign_key: { to_table: :messages }, null: true
      t.boolean :paywalled, default: false
      t.integer :price_cents, default: 0, null: false
      t.string :currency, default: "usd", null: false
      t.timestamps
    end
  end
end

```

#### `CreatePostPurchases` (Stripe Edition)

```ruby
# db/migrate/xxx_create_post_purchases.rb
class CreatePostPurchases < ActiveRecord::Migration[7.1]
  def change
    create_table :post_purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.string :stripe_checkout_session_id, null: false
      t.string :stripe_payment_intent_id
      t.integer :amount_cents, null: false
      t.string :currency, default: "usd", null: false
      t.string :status, default: "completed", null: false
      t.timestamps
    end

    add_index :post_purchases, [:user_id, :post_id], unique: true
    add_index :post_purchases, :stripe_checkout_session_id, unique: true
    add_index :post_purchases, :stripe_payment_intent_id
  end
end

```

#### `CreatePushSubscriptions`

```ruby
# db/migrate/xxx_create_push_subscriptions.rb
class CreatePushSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :p256dh_key, null: false
      t.string :auth_key, null: false
      t.string :user_agent
      t.timestamps
    end

    add_index :push_subscriptions, :endpoint, unique: true
  end
end

```

---

### 1.2 Models

```ruby
# app/models/conversation.rb
class Conversation < ApplicationRecord
  has_many :participants, class_name: "ConversationParticipant", dependent: :destroy
  has_many :users, through: :participants
  has_many :messages, -> { order(created_at: :asc) }, dependent: :destroy

  def self.between(user1, user2)
    where(conversation_type: "dm")
      .joins(:participants)
      .where(conversation_participants: { user_id: [user1.id, user2.id] })
      .group(:id)
      .having("COUNT(*) = 2")
      .first
  end

  def self.create_dm(user1, user2)
    transaction do
      conv = create!(conversation_type: "dm")
      conv.participants.create!(user: user1)
      conv.participants.create!(user: user2)
      conv
    end
  end
end

# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  has_one :promoted_post, class_name: "Post", foreign_key: :source_message_id, dependent: :nullify

  after_create_commit :broadcast_message
  after_create_commit :notify_recipients

  private

  def broadcast_message
    broadcast_append_to(
      conversation,
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
    )
  end

  def notify_recipients
    conversation.users.where.not(id: user_id).find_each do |recipient|
      PushNotificationService.send_message_notification(
        message: self,
        recipient: recipient
      )
    end
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :source_message, class_name: "Message", optional: true
  has_many :purchases, class_name: "PostPurchase", dependent: :destroy

  def paid_by?(user)
    return false unless user
    return true if user_id == user.id # Creator always has access

    purchases.exists?(user_id: user.id, status: "completed")
  end

  def price_in_dollars
    price_cents / 100.0
  end

  def signed_media_urls(expires_in: 15.minutes)
    token_key = Rails.application.credentials.bunny.storage.token_key
    return media_urls if token_key.blank?

    expires = (Time.current + expires_in).to_i

    media_urls.map do |media|
      url = "#{BunnyUploadService.cdn_base_url}/#{media['original_key']}"
      token = BunnyTokenSigner.sign(url: url, expires: expires, key: token_key)
      media.merge("url" => "#{url}?token=#{token}")
    end
  end
end

# app/models/post_purchase.rb
class PostPurchase < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :stripe_checkout_session_id, presence: true, uniqueness: true
  validates :amount_cents, presence: true
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
    conversation.messages.create!(
      user: Current.user,
      content: data["content"],
      attachments: data["attachments"] || []
    )
  end

  def read(data)
    participant = Current.user.conversation_participants.find_by!(conversation_id: data["conversation_id"])
    participant.update!(last_read_at: Time.current)
  end
end

```

### 2.2 Conversations Controller (Inertia)

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
      Current.user.update(active_conversation_id: @conversation.id)
      @messages = @conversation.messages.includes(:user).page(params[:page])
    end

    def create
      recipient = User.find(params[:user_id])
      @conversation = Conversation.between(Current.user, recipient) ||
                      Conversation.create_dm(Current.user, recipient)
      redirect_to dashboard_conversation_path(@conversation)
    end
  end
end

```

---

## Phase 3: Offline Support (IndexedDB + Dexie.js)

### 3.1 Dexie Schema (`app/frontend/lib/db.ts`)

```ts
import Dexie, { type EntityTable } from "dexie"

interface CachedMessage {
  id: number | string
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

### 3.2 Svelte Rune Store (`app/frontend/stores/chat.svelte.ts`)

```ts
import { db, type CachedMessage } from "~/lib/db"
import { getConsumer } from "~/lib/cable"

class ChatStore {
  conversations = $state<Map<number, CachedMessage[]>>(new Map())
  online = $state(navigator.onLine)
  private pendingSync = $state<Set<string>>(new Set())

  constructor() {
    window.addEventListener("online", () => this.syncPending())
    window.addEventListener("offline", () => this.online = false)
  }

  async loadConversation(id: number) {
    const cached = await db.messages
      .where("conversationId").equals(id)
      .sortBy("createdAt")
    
    this.conversations.set(id, cached)
    
    getConsumer().subscriptions.create(
      { channel: "ChatChannel", conversation_id: id },
      {
        received: (data: CachedMessage) => this.handleIncoming(data),
      }
    )
  }

  async sendMessage(conversationId: number, content: string, files?: File[]) {
    const localId = crypto.randomUUID()
    const message: CachedMessage = {
      id: localId,
      conversationId,
      userId: window.currentUserId,
      content,
      attachmentUrls: [],
      status: "pending",
      createdAt: new Date(),
      pendingAttachments: files?.map(f => ({ localBlob: f, type: f.type })),
    }
    
    await db.messages.add(message)
    this.upsertMessage(conversationId, message)

    if (this.online) {
      await this.uploadAndSend(message)
    } else {
      this.pendingSync.add(localId as string)
    }
  }

  private async uploadAndSend(message: CachedMessage) {
    // 1. Upload media files to Bunny
    // 2. Submit to Rails via Action Cable / HTTP
    // 3. Mark status = "sent" in Dexie
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

---

## Phase 4: Bunny CDN Uploads & Client-Side Canvas Blurring

### 4.1 Client-Side Fast Blurring (`app/frontend/lib/blur.ts`)

To protect Rails web processes from CPU heavy workloads, image degradation is computed via the browser's Canvas API before uploading to Bunny CDN.

```ts
export async function generateBlurredImageDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => {
      const canvas = document.createElement("canvas")
      // Downscale to 32x32 to guarantee irreversible information loss
      canvas.width = 32
      canvas.height = 32
      const ctx = canvas.getContext("2d")
      if (!ctx) return reject("Canvas context unavailable")

      ctx.filter = "blur(4px)"
      ctx.drawImage(img, 0, 0, 32, 32)
      resolve(canvas.toDataURL("image/jpeg", 0.3))
    }
    img.onerror = reject
    img.src = URL.createObjectURL(file)
  })
}

```

### 4.2 Rails Bunny Upload Service

```ruby
# app/services/bunny_upload_service.rb
class BunnyUploadService
  BUNNY_STORAGE_URL = Rails.application.credentials.bunny.storage.base_url
  ZONE_NAME = Rails.application.credentials.bunny.storage.zone_name
  PASSWORD = Rails.application.credentials.bunny.storage.password

  def self.generate_signed_upload_url(filename:, content_type:, user_id:)
    path = "uploads/#{user_id}/#{SecureRandom.uuid}/#{filename}"
    url = "#{BUNNY_STORAGE_URL}/#{ZONE_NAME}/#{path}"
    
    {
      upload_url: url,
      public_cdn_url: "#{cdn_base_url}/#{path}",
      headers: {
        "AccessKey" => PASSWORD,
        "Content-Type" => content_type,
      },
      path: path,
    }
  end

  def self.cdn_base_url
    Rails.application.credentials.bunny.storage.cdn_url
  end
end

```

### 4.3 Upload Controller

```ruby
# app/controllers/uploads_controller.rb
class UploadsController < ApplicationController
  before_action :require_authentication

  def sign
    result = BunnyUploadService.generate_signed_upload_url(
      filename: params[:filename],
      content_type: params[:content_type],
      user_id: Current.user.id
    )

    render json: result
  end
end

```

---

## Phase 5: "Promote to Post" Feature

### 5.1 Posts Controller

```ruby
# app/controllers/dashboard/posts_controller.rb
module Dashboard
  class PostsController < BaseController
    def create
      @post = Current.user.posts.create!(
        title: params[:title],
        description: params[:description],
        media_urls: params[:media_urls],
        source_message_id: params[:source_message_id],
        paywalled: params[:paywalled] || false,
        price_cents: (params[:price_usd].to_f * 100).to_i,
        currency: params[:currency] || "usd"
      )

      redirect_to dashboard_post_path(@post)
    end

    def show
      @post = Post.find(params[:id])

      if @post.paywalled? && !@post.paid_by?(Current.user)
        render "posts/show_blurred"
      else
        @media_urls = @post.signed_media_urls(expires_in: 15.minutes)
        render "posts/show"
      end
    end
  end
end

```

### 5.2 Bunny Token Signer Service

```ruby
# app/services/bunny_token_signer.rb
class BunnyTokenSigner
  def self.sign(url:, expires:, key:)
    uri = URI.parse(url)
    path = uri.path
    token_string = "#{key}#{path}#{expires}"
    token = Digest::SHA256.hexdigest(token_string)
    "expires=#{expires}&token_signature=#{token}"
  end
end

```

---

## Phase 6: Paywall Enforcement (Stripe Integration)

### 6.1 Stripe Checkout Controller

```ruby
# app/controllers/dashboard/purchases_controller.rb
module Dashboard
  class PurchasesController < BaseController
    def create
      post = Post.find(params[:post_id])

      if post.paid_by?(Current.user)
        return redirect_to dashboard_post_path(post), notice: "You already own access to this post."
      end

      session = Stripe::Checkout::Session.create(
        payment_method_types: ["card"],
        line_items: [{
          price_data: {
            currency: post.currency,
            product_data: {
              name: post.title.presence || "Paywalled Post ##{post.id}",
              description: post.description&.truncate(100),
            },
            unit_amount: post.price_cents,
          },
          quantity: 1,
        }],
        mode: "payment",
        metadata: {
          user_id: Current.user.id,
          post_id: post.id,
        },
        success_url: "#{dashboard_post_url(post)}?purchased=true",
        cancel_url: dashboard_post_url(post),
      )

      render json: { checkout_url: session.url }
    end
  end
end

```

### 6.2 Stripe Webhook Handler (Asynchronous & Verified)

```ruby
# app/controllers/webhooks/stripe_controller.rb
module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      endpoint_secret = Rails.application.credentials.stripe.webhook_secret

      begin
        event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError, Stripe::SignatureVerificationError
        return head :bad_request
      end

      case event.type
      when "checkout.session.completed"
        session = event.data.object
        fulfill_purchase(session)
      end

      head :ok
    end

    private

    def fulfill_purchase(session)
      user_id = session.metadata.user_id
      post_id = session.metadata.post_id

      PostPurchase.find_or_create_by!(
        stripe_checkout_session_id: session.id
      ) do |purchase|
        purchase.user_id = user_id
        purchase.post_id = post_id
        purchase.stripe_payment_intent_id = session.payment_intent
        purchase.amount_cents = session.amount_total
        purchase.currency = session.currency
        purchase.status = "completed"
      end
    end
  end
end

```

---

## Phase 7: Service Worker & Offline PWA Shell

```js
// public/service-worker.js
self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url)
  
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

## Phase 8: Push Notifications (Web Push)

### 8.1 Push Notification Service

```ruby
# app/services/push_notification_service.rb
class PushNotificationService
  def self.send_message_notification(message:, recipient:)
    return if recipient.active_conversation_id == message.conversation_id

    sender_name = message.user.name || message.user.handle
    body = if message.content.present?
             message.content.truncate(100)
           elsif message.attachments.any?
             "Sent an attachment"
           else
             "New message"
           end

    recipient.push_subscriptions.find_each do |subscription|
      send_web_push(
        subscription: subscription,
        title: sender_name,
        body: body,
        path: "/dashboard/conversations/#{message.conversation_id}",
        tag: "conversation-#{message.conversation_id}"
      )
    rescue WebPush::InvalidSubscription, WebPush::ExpiredSubscription
      subscription.destroy!
    end
  end

  private

  def self.send_web_push(subscription:, title:, body:, path:, tag:)
    vapid = Rails.application.credentials.web_push

    WebPush.payload_send(
      message: JSON.generate({
        title: title,
        options: {
          body: body,
          tag: tag,
          data: { path: path }
        }
      }),
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh_key,
      auth: subscription.auth_key,
      vapid: {
        subject: vapid[:subject],
        public_key: vapid[:vapid_public],
        private_key: vapid[:vapid_private],
      }
    )
  end
end

```

---

## Complete File Tree Summary

```
New/Modified Files:

app/
  models/
    conversation.rb
    conversation_participant.rb
    message.rb
    post.rb
    post_purchase.rb
    push_subscription.rb
  controllers/
    uploads_controller.rb
    dashboard/
      conversations_controller.rb
      messages_controller.rb
      posts_controller.rb
      purchases_controller.rb
    webhooks/
      stripe_controller.rb
    push/
      subscriptions_controller.rb
  channels/
    chat_channel.rb
  services/
    bunny_upload_service.rb
    bunny_token_signer.rb
    push_notification_service.rb
  frontend/
    lib/
      blur.ts
      cable.ts
      db.ts
      push.ts
    stores/
      chat.svelte.ts

config/
  routes.rb

db/
  migrate/
    xxx_create_conversations.rb
    xxx_create_conversation_participants.rb
    xxx_create_messages.rb
    xxx_create_posts.rb
    xxx_create_post_purchases.rb
    xxx_create_push_subscriptions.rb

Gemfile

```

---

## Implementation Order Schedule

| Priority | Phase | Scope |
| --- | --- | --- |
| **1** | Phase 1 — Models & Database Migrations | Basic data structural foundation |
| **2** | Phase 2 — Real-time Action Cable Chat | Core socket chat system |
| **3** | Phase 4 — Bunny Direct Uploads & Client Blurring | Media handling pipeline |
| **4** | Phase 3 — Offline Dexie IndexedDB Queue | Offline message persistence |
| **5** | Phase 8 — Web Push Notifications | Remote background user updates |
| **6** | Phase 5 — Promote Message to Post Action | Post creation from media |
| **7** | Phase 6 — Stripe Paywall Checkout & Webhooks | Payment processing & lock verification |
| **8** | Phase 7 — PWA Shell & Asset Cache | Offline shell caching |

