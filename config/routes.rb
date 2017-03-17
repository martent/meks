Rails.application.routes.draw do
  root 'statistics#index'

  get '/login' => 'login#new'
  post '/login' => 'login#create'
  get '/logout' => 'login#destroy'

  namespace :saml do
    get :sso
    post :consume
    get :consume # Not used
    get :metadata
    get :logout
  end

  get '/refugees/suggest'
  get '/refugees/search' => 'refugees#search'
  get '/refugees/drafts' => 'refugees#drafts'
  get '/refugees' => 'refugees#search'

  resources :refugees do
    resources :placements do
      get :move_out
      patch :move_out_update
    end
    resources :relationships
  end

  resources :homes
  resources :moved_out_reasons, except: :show
  resources :legal_codes, except: :show
  resources :deregistered_reasons, except: :show
  resources :target_groups, except: :show
  resources :type_of_housings, except: :show
  resources :owner_types, except: :show
  resources :type_of_relationships, except: :show
  resources :municipalities, except: :show
  resources :countries, except: :show
  resources :languages, except: :show
  resources :genders, except: :show
  resources :users, only: :index
  resources :statistics, only: :index

  get  'reports' => 'reports#index'
  post 'reports/generate'
  get  'reports/status/:job_id/:file_id' => 'reports#status', as: 'reports_status'
  get  'reports/download/:id' => 'reports#download', as: 'reports_download'
  get  'reports/download_pre_generated/:id' => 'reports#download_pre_generated', as: 'reports_download_pre_generated'

  match '*path', via: :all, to: 'errors#not_found'
end
