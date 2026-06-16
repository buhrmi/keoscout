class Dashboard::BaseController < ApplicationController
  before_action :authenticate_user!

  private

  def authenticate_user!
    unless Current.user
      session[:redirect_authenticated_user_to] = request.fullpath if request.get?
      redirect_to root_path
    end
  end
end
