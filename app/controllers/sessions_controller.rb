class SessionsController < ApplicationController
  def new
    render layout: false if params[:provider]
  end

  def create
    auth = request.env["omniauth.auth"]
    Current.user = Identity.from_omniauth!(auth,
      scout_id: session[:scout_id],
      share_percentage: cookies[:share_percentage],
      preferred_currency: preferred_currency_from_request
    ).user

    session[:user_id] = Current.user.id
    cookies.delete(:scout_id)
    cookies.delete(:share_percentage)

    flash[:notice] = "Signed in successfully."
    session[:redirect_authenticated_user_to] ||= dashboard_root_path
    render layout: false
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out successfully."
  end

  private

  def preferred_currency_from_request
    locale = request.headers["Accept-Language"]&.scan(/[a-z]{2}/i)&.first&.downcase
    case locale
    when "vi" then "VND"
    when "ja" then "JPY"
    when "ko" then "KRW"
    when "zh" then "CNY"
    when "de", "fr", "it", "es", "nl", "pt" then "EUR"
    when "gb" then "GBP"
    else "USD"
    end
  end
end
