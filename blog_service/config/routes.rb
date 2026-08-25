Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "hello", to: "hello#index"
      resources :users
      resources :categories
      resources :posts
    end
  end

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
end
