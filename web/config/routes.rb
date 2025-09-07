Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :recruiters, only: [:index, :show], param: :slug do
    resources :reviews, only: [:new]
  end
  resources :reviews, only: [:create]
end
