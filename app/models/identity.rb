class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :provider_id, presence: true
  validates :provider_id, uniqueness: { scope: :provider }

  def self.from_omniauth!(auth_hash, params)
    Identity.where(provider: auth_hash.provider, provider_id: auth_hash.uid).first_or_initialize do |identity|
      identity.user = User.create!(
        email: auth_hash.info.email.presence || "zalo-#{auth_hash.uid}@user.keoscout.com",
        name: auth_hash.info.name.presence || "User #{auth_hash.uid}",
        password: SecureRandom.base58(10),
        **params
      )
    end.tap do |identity|
      identity.update!(info: auth_hash.info.to_h)
    end
  end
end
