# frozen_string_literal: true

# Monkey-patch InertiaRails to support `inertia: { frame: "_top" }` option in redirect_to.
#
# Usage:
#   redirect_to some_path, inertia: { frame: "_top" }
#
# This sets the X-Inertia-Frame response header on the subsequent request.

module InertiaFrameExtension
  def self.prepended(base)
    # `base` is InertiaRails::Controller — an ActiveSupport::Concern module.
    # `before_action` is only available on the controller class after the concern
    # is included, so we wrap the concern's `included` callback to register ours.
    base.singleton_class.prepend(Module.new do
      def included(controller_class)
        super
        controller_class.before_action :set_inertia_frame_header
      end
    end)
  end

  private

  def capture_inertia_session_options(options)
    super
    return unless (inertia = options[:inertia])
    session[:inertia_frame] = inertia[:frame] if inertia.key?(:frame)
  end

  def set_inertia_frame_header
    response["X-Inertia-Frame"] = session[:inertia_frame] if session[:inertia_frame]
  end

  def redirect_back(**options)
    # For Inertia requests, use X-Inertia-Referer (the frame's URL)
    # instead of the standard Referer header (the host page's URL).
    if (inertia_referer = request.headers["X-Inertia-Referer"])
      # Echo the originating frame so Inertia renders the response there.
      frame = request.headers["X-Inertia-Frame"]
      session[:inertia_frame] = frame
      redirect_to inertia_referer, **options
    else
      super
    end
  end
end

module InertiaFrameMiddlewareExtension
  def response
    status, headers, body = super
    request = ActionDispatch::Request.new(@env)
    request.session.delete(:inertia_frame) unless keep_inertia_session_options?(status) || !request.session.loaded?
    [ status, headers, body ]
  end
end

Rails.application.config.to_prepare do
  InertiaRails::Controller.prepend(InertiaFrameExtension)
  InertiaRails::Middleware::InertiaRailsRequest.prepend(InertiaFrameMiddlewareExtension)
end
