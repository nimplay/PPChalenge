Rails.application.routes.draw do
  # Configuración de Swagger UI
  if Rails.env.development? || Rails.env.staging?
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end

  if Rails.env.production?
    authenticate :user, ->(user) { user.admin? } do
      mount Rswag::Ui::Engine => "/api-docs"
      mount Rswag::Api::Engine => "/api-docs"
    end
  end

  # Rutas básicas
  get "up" => "rails/health#show", as: :rails_health_check
  root "welcome#index"

  # Rutas para controladores principales (fuera de API)
  resources :products
  resources :categories

  # API V1
  namespace :api do
    namespace :v1 do
      # Autenticación JWT
      post "auth", to: "authentication#login"
      delete "auth/logout", to: "authentication#logout"

      # Rutas para controladores anidados
      scope module: :categories do
        get "categories/most_purchased", to: "most_purchased#index"
        get "categories/top_revenue", to: "top_revenue#index"
      end

      scope module: :purchases do
        get "purchases/search", to: "search#index"
        get "purchases/statistics", to: "statistics#index"
      end

      # Recursos estándar de API
      resources :products
      resources :customers
    end
  end
end
