Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  devise_for :users

  # API endpoints for cascading selects
  namespace :api do
    resources :brands, only: [ :index ]
    resources :product_lines, only: [ :index ]
    resources :paints, only: [ :index, :show ]
  end

  resources :paints do
    get :search, on: :collection
    get :similar, on: :member
  end
  resources :user_paints do
    collection do
      get :bulk_import
      post :bulk_search
      post :bulk_search_from_photo
      get :color_wheel
    end
  end
  authenticated :user do
    get "paints/search", to: "paints#search"
    root "dashboard#index", as: :user_root
  end

  # Projects
  resources :projects do
    collection do
      get :public, to: "projects#public_index"
    end
    resources :project_updates, except: [:index, :show]
  end
  get "/p/:token", to: "projects#restricted", as: :restricted_project

  # Videos
  resources :videos, only: [:index, :new, :create, :show, :destroy] do
    collection do
      get :public, to: "videos#public_index"
    end
    get "alternatives/:brand_slug", action: :alternatives, on: :member, as: :alternatives
    resources :video_paints, only: [:edit, :update]
  end

  resources :pages

  root "pages#welcome"
end
