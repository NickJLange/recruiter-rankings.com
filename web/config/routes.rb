Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  
  root "pages#home"
  get '/about',    to: 'pages#about'
  get '/policies', to: 'pages#policies'
  get '/search',   to: 'search#index'

  # Legacy /recruiters URL — redirect to /person (SEO-safe 301, no named helper)
  get '/recruiters', to: redirect { |_p, req|
    "/person#{req.query_string.present? ? "?#{req.query_string}" : ''}"
  }, as: nil

  resources :recruiters, only: [:index, :show, :new, :create], path: 'person', param: :slug do
    resources :reviews, only: [:new, :index]
  end
  resources :reviews, only: [:create]
  resources :companies, only: [:index, :show]

  # Review flow entry
  get "reviews/new", to: "reviews#new_global", as: :new_global_review

  # Unified claim identity (users or recruiters)
  get  "/claim_identity/new",    to: "claim_identity#new",    as: :new_claim_identity
  post "/claim_identity",        to: "claim_identity#create", as: :claim_identity
  post "/claim_identity/verify", to: "claim_identity#verify", as: :verify_claim_identity

  resources :identity_verifications, only: [:new, :create, :show]
  resource :subscription, only: [:new, :create]

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
          patch :unhide
        end
      end
    end
    
    resources :identity_verifications, only: [:index, :update] do
      member do
        patch :approve
        patch :reject
      end
    end
  end

end
