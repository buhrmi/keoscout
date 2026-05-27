class Dashboard::BaseController < ApplicationController
  before_action :authenticate_user!

  private

  def authenticate_user!
    unless Current.user
      session[:redirect_authenticated_user_to] = request.fullpath if request.get?
      redirect_to new_session_path
    end
  end
end
