class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_current_user
  before_action :set_current_url_options
  before_action :redirect_authenticated_user
  before_action :save_scout_id
  before_action :set_frame_header

  use_inertia_instance_props

  rescue_from ActiveRecord::RecordInvalid do |exception|
    raise exception unless request.inertia?

    model_key = exception.record.model_name.singular
    redirect_back inertia: {
      errors: exception.record.errors.to_hash.transform_keys { |attr| :"#{model_key}.#{attr}" }
    }
  end

  rescue_from ActionController::BadRequest do |exception|
    flash[:error] = exception.message
    redirect_back(fallback_location: root_path)
  end

  inertia_share do
    {
      host: request.base_url,
      current_user: Current.user.as_json(User::JSON_OPTIONS),
      referrer: session[:scout_id] && User.find_by(id: session[:scout_id]).as_json(only: [ :name ])
    }
  end

  private

  def set_frame_header
    response["X-Inertia-Frame"] = flash[:frame] if flash[:frame]
  end

  def inertia_referer
    request.headers["X-Inertia-Referer"] || request.referer
  end

  def redirect_back(fallback_location: root_path, **args)
    if request.inertia?
      redirect_to inertia_referer || fallback_location, **args
    else
      super
    end
  end

  def set_current_user
    Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def set_current_url_options
    ActiveStorage::Current.url_options = { host: request.base_url }
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
