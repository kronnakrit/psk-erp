Rails.application.routes.draw do
  # API docs — only accessible in development/test to prevent schema disclosure in production
  if Rails.env.local?
    mount Rswag::Ui::Engine => '/api-docs'
    mount Rswag::Api::Engine => '/api-docs'
  end
  # Web authentication (Devise HTML views)
  devise_for :users, path: "", path_names: { sign_in: "login", sign_out: "logout" },
                     controllers: { sessions: "devise/sessions" }

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Locale switcher
  resource :locale, only: :update

  # Web UI routes
  resources :users, except: :show do
    member do
      patch :activate
      patch :deactivate
    end

    resource :force_password, only: :update, module: :users, controller: :force_password
  end

  resource :profile, only: %i[show update]

  resources :roles
  resources :permissions, only: :index
  resources :countries
  resource :company_setting, only: %i[edit update]
  resources :logistic_companies do
    member do
      patch :activate
      patch :deactivate
    end
  end
  resources :customers
  resources :suppliers
  resources :purchase_orders do
    member do
      post :confirm
    end
    resources :purchase_order_lines, only: %i[create update destroy]
  end
  resources :brands
  resources :product_classes do
    resources :attributes
  end
  resources :product_categories
  resources :product_attributes
  resources :products do
    resources :product_images, only: %i[index create destroy]
    member do
      get  :unit_definitions
      get  :lots
      post :duplicate
    end
  end
  resources :child_products, only: %i[update destroy]
  resources :uploads, only: %i[index create] do
    collection do
      get :template
    end
  end
  resources :branches
  resources :stock_locations
  resources :stocks, only: %i[index show update] do
    member do
      post :deposit
      post :withdraw
      post :recalculate_checkpoint
      get  :transactions
    end
  end

  resources :unit_groups do
    member do
      patch :set_default
    end
    resources :unit_definitions, only: %i[create destroy] do
      member do
        patch :set_main
      end
    end
  end

  resources :invoices do
    resources :invoice_orders, only: %i[create destroy]
    resources :invoice_images, only: %i[create destroy]

    member do
      post :cancel
      post :mark_paid
      post :reopen
      get  :audit_trail
      get  :print
      get  :add_orders
    end

    collection do
      get  :draft
      get  :paid
      get  :cancelled
      post :bulk_update_status
    end
  end

  resources :orders do
    resources :order_lines,  only: %i[create update destroy]
    resources :order_images, only: %i[index create destroy]

    member do
      get  :export
      get  :export_token
      get  :delivery_order
      get  :audit_trail
      post :duplicate
    end

    collection do
      get  :draft
      get  :paid
      get  :completed
      get  :cancelled
      get  :dashboard
      get  :advance_search
      get  :download
      get  :scan
      get  :find_by_number
      post :filter
      post :bulk_update_status
      post :combine_bills
      post :export_excel
    end
  end

  # API v1
  namespace :api do
    namespace :v1 do
      # Auth — separate devise_scope for the API so Devise warden is active
      devise_scope :user do
        post   "auth/sign_in",  to: "auth/sessions#create"
        delete "auth/sign_out", to: "auth/sessions#destroy"
      end

      post "auth/refresh", to: "auth/tokens#refresh"
      post "auth/verify",  to: "auth/tokens#verify"

      # User management
      resources :users, except: :show do
        member do
          patch :activate
          patch :deactivate
        end
      end

      resource :profile, only: %i[show update]
      resources :roles
      resources :permissions, only: :index
      resources :countries, only: %i[index show]
      resources :logistic_companies do
        collection do
          post :filter
        end
      end
      resources :customers do
        collection do
          post :filter
          get  :search
        end
      end

      namespace :catalogs do
        get :list_product_categories, to: "product_categories#list_product_categories"
        resources :products, only: %i[index show] do
          member do
            get :parent
            get :child
            get :advance_search
            get "last_price/:customer_id", to: "products#last_price", as: :last_price
            get :last_purchase_cost
            get :lots
            get :fifo_cost
          end
          collection do
            post :filters
          end
        end
      end

      resources :orders do
        collection do
          get  :draft
          get  :paid
          get  :completed
          get  :cancelled
          get  :dashboard
          post :advance_search
          post :filters
          post :bulk_update_status
          post :report_order
          post :customer_report
          post :sales_report
        end
      end
    end
  end

  root to: "dashboard#index"
end
