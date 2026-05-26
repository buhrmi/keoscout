class SessionsController < ApplicationController
  def new
    render layout: false if params[:provider]
  end

  def create
    auth = request.env["omniauth.auth"]
    Current.user = Identity.from_omniauth!(auth).user

    session[:user_id] = Current.user.id

    flash[:notice] = "Signed in successfully."
    render layout: false
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out successfully."
  end
end
