class SessionsController < ApplicationController
  def new
    render layout: false if params[:provider]
  end

  def create
    if request.env["omniauth.auth"].present?
      create_from_omniauth
    else
      create_from_email
    end
  end

  def create_from_email
    user = User.authenticate_by(login_params)
    if user
      session[:user_id] = user.id
      flash[:frame] = "_top"
      redirect_to dashboard_root_path, notice: "Signed in successfully."
    else
      flash[:alert] = "Invalid email or password."
      redirect_to new_session_path
    end
  end

  def create_from_omniauth
    auth = request.env["omniauth.auth"]
    scout = User.find_by(id: session[:scout_id]) if session[:scout_id].present?

    # Only allow new signups via invitation
    unless Identity.exists?(provider: auth.provider, provider_id: auth.uid) || scout.present?
      flash[:alert] = "An invitation is required to sign up."
      render layout: false
      return
    end

    Current.user = Identity.from_omniauth!(auth,
      scout_id: scout&.id,
      share_percentage: cookies[:share_percentage]
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

  def login_params
    params.require(:user).permit(:email, :password)
  end
end
