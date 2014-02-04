#class BlacklistConstraint
#  def initialize
#  end
#
#  def matches?(request)
#    app_config(:authorized_ips).split(',').include?(request.remote_ip)
#  end
#end

Tibcodocs::Application.routes.draw do

  resources :doc_ftps

  root :to => "products#index"

  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  match 'search' => "landing#search", :as => :search
  match 'folder_path' => "landing#folder_path", :as => :folder_path
  match 'employee/products' => "landing#employee"#, :constraints => BlacklistConstraint.new
  match 'public/products' => "landing#public"#, :constraints => BlacklistConstraint.new
  match 'authorize_tc_login' => "landing#authorize_tc_login"
  match 'change_user_email' => "landing#change_user_email"
  get   'doc_names'  => 'products#doc_names'
  #match '/product/:product_id/rate' => 'ratings#rate', :as => :ratings

  resources :groups                                         #  resources :parent_groups
  resources :user_domains do
    collection do
      post "authenticate"
      get "authentication"
    end
  end
  resources :users, :user_sessions
  resources :products do
    collection do
      post 'search'
      get 'find'
      get 'search_tab'
      get 'a_z_products'
      get 'suggest'
      post 'create_parent'
      get 'new_parent'
      get 'audit_info'
      get 'get_latest_detail_release_report'
      get 'get_latest_brief_release_report'
      get 'get_breadcum_report'
      get 'get_ooc_report'
      get 'get_all_reports'
      get 'get_ga_report'
    end
    member do
      get 'edit_parent'
      get 'feedback'
      get 'get_csv_report'
      put 'update_parent'
      get 'delete_parent'
      get 'preview'
      get 'fill_product_find'
    end
#    resources :versions
#    resources :comments
    resources :documents do
      collection do
        post 'document_order'
      end
      member  do
        get 'update_page_count'
        get 'out_of_cycle'
      end
    end
  end

  resources :tibbr_integration, :path_names => { :new => 'login' } do
    collection do
      post "login"
      get "logout"
      post "create_post"
    end
    member do
      get 'destroy_post'
    end
  end

  resources :ldap_logins, :path => "tibcommunity_login",:only => [:new],:path_names => { :new => 'login' } do
    collection do
      post "login"
      get "logout"
    end
  end

  resources :doc_admin_instructions , :only => [:index]



  #match '*a', :to => redirect("/")
end