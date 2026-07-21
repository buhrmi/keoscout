u = User.find_or_create_by!(id: 1) do |user|
  user.email = "stefan@keoscout.com"
  user.password = SecureRandom.base58(10)
  user.name = "Stefan Buhrmester"
  user.handle = "buhrmi"
end

u.identities.find_or_create_by!(provider: "zalo", provider_id: "206492388818353401")


u.profile_image.attach(
  io: File.open(Rails.root.join("db/seeds/profile.jpg")),
  filename: "profile.jpg"
)

u.header_image.attach(
  io: File.open(Rails.root.join("db/seeds/header.png")),
  filename: "header.png"
)
