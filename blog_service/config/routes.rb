Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Auth routes
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"

      get "hello", to: "hello#index"
      resources :users
      resources :categories
      resources :posts do
        resources :comments, only: [:create]
        resource :like, only: [:create, :destroy]
      end
    end
  end

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
end
