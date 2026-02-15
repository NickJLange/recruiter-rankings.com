Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  
  root "recruiters#index"

  resources :recruiters, only: [:index, :show], path: 'person', param: :slug do
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

  if Rails.env.test? || Rails.env.development?
    # Utils for dev/test login
    get  "/login",  to: "sessions#new",     as: :login
    post "/login",  to: "sessions#create"
    match "/logout", to: "sessions#destroy", via: [:delete, :get], as: :logout
    
    match '/utils/login', via: [:get, :post], as: :utils_login, to: ->(env) {
      req = Rack::Request.new(env)
      env['rack.session'][:user_id] = req.params['user_id']
      [200, {}, ['ok']]
    }
  end
end
