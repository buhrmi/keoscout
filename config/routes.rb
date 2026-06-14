Rails.application.routes.draw do
  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |_params, req| "#{req.protocol}localhost:#{req.port}#{req.fullpath}" }
  end

  resource :session

  namespace :dashboard do
    resource :user
    resources :friends
    resources :posts
    root "users#show"
  end

  inertia "terms" => "static/terms", as: :terms
  get "up" => "rails/health#show", as: :rails_health_check

  # OmniAuth callback routes
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "users#new"
end
