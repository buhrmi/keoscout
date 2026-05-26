OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :zalo, Rails.application.credentials.dig(:zalo, :app_id), Rails.application.credentials.dig(:zalo, :private_key)
end
