class User < ApplicationRecord
  JSON_OPTIONS = {
    only: [ :id, :name, :handle, :preferred_currency ],
    include: {
      profile_image: {},
      header_image: {}
    }
  }

  has_secure_password
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_one_attached :profile_image
  has_one_attached :header_image

  has_many :identities, dependent: :destroy
  has_many :posts # TODO: what to do with posts when user is deleted?

  after_create_commit :fetch_profile_image

  private

  def fetch_profile_image
    return if profile_image.attached?

    identity = identities.find { |identity| identity.info["image"].present? }
    if identity
      ext = File.extname(identity.info["image"])
      profile_image.attach(io: URI.open(identity.info["image"]), filename: "#{id}_profile#{ext}")
    end
  end
end
