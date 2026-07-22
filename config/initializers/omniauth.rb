OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :zalo, Rails.application.credentials.dig(:zalo, :app_id), Rails.application.credentials.dig(:zalo, :private_key)
end

# Monkey-patch: Zalo's info block crashes with `undefined method '[]' for nil`
# when the user has no profile picture (raw_info['picture'] is nil).
# Also add email to the API request.
module OmniAuth
  module Strategies
    class Zalo
      def info
        picture = raw_info["picture"]
        image_url = if picture.is_a?(Hash) && picture["data"].is_a?(Hash)
                      picture["data"]["url"]
        end

        {
          name:  raw_info["name"],
          email: raw_info["email"],
          image: image_url
        }
      end

      # Override to also request email field from Zalo API
      def get_user_info
        @raw_info ||= JSON.load(
          access_token.get(
            "https://graph.zalo.me/v2.0/me?access_token=#{access_token.token}&fields=id,birthday,name,gender,picture,phone,email"
          ).body
        )
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end
