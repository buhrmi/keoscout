class User < ApplicationRecord
  has_one_attached :profile_image

  has_many :identities, dependent: :destroy
  has_many :posts # TODO: what to do with posts when user is deleted?

  after_create_commit :fetch_profile_image

  private

  def fetch_profile_image
    return if profile_image.attached?

    identity = identities.find { |identity| identity.info["image"].present? }
    if identity
      profile_image.attach(io: URI.open(identity.info["image"]), filename: "#{id}_profile_image.jpg")
    end
  end
end
