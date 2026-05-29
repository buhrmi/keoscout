User.find_or_create_by!(id: 1) do |user|
  user.email = "stefan@keoscout.com"
  user.name = "Stefan Buhrmester"
  user.password = SecureRandom.base58(10)
end
