class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_current_user
  before_action :redirect_authenticated_user
  before_action :save_scout_id

  use_inertia_instance_props

  inertia_share do
    {
      current_user: Current.user&.slice(:id, :name, :email)
    }
  end

  private

  def set_current_user
    Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def save_scout_id
    if params[:scout_id]
      session[:scout_id] = params[:scout_id]
    end
  end

  def redirect_authenticated_user
    if Current.user && path = session.delete(:redirect_authenticated_user_to)
      redirect_to path
    end
  end
end
