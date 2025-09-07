Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :recruiters, only: [:index, :show], param: :slug do
    resources :reviews, only: [:new]
  end
  resources :reviews, only: [:create]

  get "/sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }

  namespace :admin do
    resources :reviews, only: [:index] do
      member do
        patch :approve
        patch :flag
        patch :remove
      end
      resources :responses, only: [:create]
    end
  end
end
