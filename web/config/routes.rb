Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :recruiters, only: [:index, :show], param: :slug do
    resources :reviews, only: [:new, :index]
  end
  resources :reviews, only: [:create]
  resources :companies, only: [:index, :show]

  # Reveal known recruiters (email or LinkedIn URL + optional company confirm)
  get  "/reveal", to: "reveals#new",    as: :new_reveal
  post "/reveal", to: "reveals#create", as: :reveal

  # Unified claim identity (users or recruiters)
  get  "/claim_identity/new",    to: "claim_identity#new",    as: :new_claim_identity
  post "/claim_identity",        to: "claim_identity#create", as: :claim_identity
  post "/claim_identity/verify", to: "claim_identity#verify", as: :verify_claim_identity

  get "/sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }

  namespace :admin do
    get "/" => "dashboard#index", as: :dashboard
    resources :reviews, only: [:index] do
      member do
        patch :approve
        patch :flag
        patch :remove
      end
      resources :responses, only: [:create] do
        member do
          patch :hide
          patch :show
        end
      end
    end
  end
end
