class TibbrIntegrationController < ApplicationController

  #This controller dedicated to the use tibbr for commenting on the HTML documents. The look an


  #layout nil
  layout 'tibbr_integration'

  helper_method :get_previous_url
  def new
    @success = {:active_tab => "partners-and-customers-login"}
  end

  def login
    if logged_in? and current_user_is_admin?
      @user_session = UserSession.find
      unless @user_session.blank?
        @user_session.destroy
        session.delete(:this_url)
        cookies.delete("tibco-docs-login")
      end
    end
    #url = app_config(:tibcommunity,:authentication_url)
    #data = RestClient.post(url,{:username => params[:ldap_credentials][:username],:password => params[:ldap_credentials][:password]})
    #@success = ActiveSupport::JSON.decode(data)
    #@success[:active_tab] = params[:ldap_credentials][:active_tab]
    url = app_config(:tibcommunity,:authentication_url)
    @success = {}
    #  data = RestClient.post(url,{:username => params[:ldap_credentials][:username],:password => params[:ldap_credentials][:password]})
    begin
      data = RestClient.post(url,{:params => {:login => params[:ldap_credentials][:username],:password => params[:ldap_credentials][:password]}})
      @success = ActiveSupport::JSON.decode(data)
      @success[:active_tab] = params[:ldap_credentials][:active_tab]
    rescue => error
      Rails.logger.info "Error in tibcommunity login for user '#{params[:ldap_credentials][:username]}'"
      Rails.logger.info error.class
      Rails.logger.info error.message
      Rails.logger.info error.backtrace
    end
    if @success.blank?
      @success = {}
      @success[:error] = "Username or Password is invalid."
      render :action => 'new'
    else
      if @success['authenticated'] == false
        @success[:error] = "Username or Password is invalid."
        @success[:active_tab] = params[:ldap_credentials][:active_tab]
        render :action => 'new'
      else
        if valid_user_group?
          session.delete(:this_url)
          session[:employee_login] = {"name"=>@success['display_name'], "email"=>@success['email']}
          cookies["tibco-docs-login"] = {:value => true}
          session[:last_request_time_employee] = Time.now.utc
          #create_n_login_tibbr_user(@success,params[:ldap_credentials][:username])
          if params[:ldap_credentials][:redirect_url].blank?
            session[:this_url] = session[:redirect_after_login]
            redirect_to get_previous_url
          else
            redirect_to root_url+"emp/#{params[:ldap_credentials][:redirect_url]}"
          end
        else
          @success[:error] = "You do not have permissions."
          render :action => 'new'
        end

      end
    end
  end


  def logout
    if session.has_key?(:employee_login)
      session.delete(:employee_login)
      session.delete(:this_url)
      session.delete(:user_domain_auth_email)
      session.delete(:tibbr_user)
      session.delete(:last_request_time_employee)
      cookies.delete("tibco-docs-login")
      flash[:notice] = "TIBCOmmunity Logged out."
    end
    session[:product_path] = root_url
    redirect_to get_previous_url
  end

  def valid_user_group?
    is_valid =  TibbrIntegration.find_group_of_user(@success)
    if is_valid[0]
      session[:login_as] = is_valid[1].first
      return true
    else
      return false
    end
  end

  def sync_with_tibbr
    TibbrIntegration.sync_with_tibbr
  end

  def index
    url = params[:url]
    if url=='emp/activematrix-businessworks-express/1.0.0-november-2013/doc/html'
      redirect_to('/pub/activematrix-businessworks-express/1.0.0-november-2013/doc/html/index.html')
    else
      unless url.split('/').first == 'emp' && !logged_in?
        @doc_url = params[:url]
        @product = params[:product]
        @loading_blank_html = root_url + @doc_url[0..@doc_url.rindex("/")]  + "wwhelp/wwhimpl/common/html/blank.htm"
      else
        store_product_path
        flash[:Need_Login?]= app_config(:document_require_login_message)
        redirect_to(new_ldap_login_path)
      end
    end
  end

  def create_post

    product = Product.find(params[:prod])
    unless params[:message][:url].blank?
      subject_name = ""
      subject_string = product.subject_name
      url_parts = params[:message][:url].split('#')
      unhashed = url_parts.first.gsub(/[^a-zA-Z0-9]/,'_')
      hashed = url_parts.last
      unless url_parts.size == 1
        underscored_url_string = "#{unhashed}_#{hashed}"
        url = "?url=#{unhashed}&hash=#{hashed}"
      else
        underscored_url_string = "#{unhashed}"
        url = "?url=#{unhashed}"
      end
      subject = TibbrIntegration.find_or_create_subject_by_name("#{subject_string}.#{underscored_url_string}")
      if subject['name']
        subject_name =  subject['name']
      else
        subject_name =   "#{subject_string}.#{underscored_url_string}"
      end
    else
      subject_name = product.subject_name
    end
    if logged_in? && current_user_is_employee?
      TibbrIntegration.post_message_on_subject(params[:message],subject_name,session[:tibbr_user][:auth_token])
    end
    response = params[:message][:url].blank? ? "var product_url='#{tibbr_integration_path(product.id)}'" : "var product_url='#{tibbr_integration_path(product.id)}#{url}'"
    render :js => response, :status => :ok
  end

  def show
    if params['url'].blank?
      product = Product.find(params[:id])
      subject_string = product.subject_name
      @messages = TibbrIntegration.get_messages_on_subject(subject_string)
      @active_tab = 'tib-post_question-post'
      unless  @messages.blank?
        @messages.map do |message|
          if message['messages'].count == 2
            message['messages']= TibbrIntegration.get_all_message_data(message['id'])['messages']
          end
        end
      else
        @messages = []
      end
      #@messages.map do |message|
      #  if message['messages'].count == 2
      #    message['messages']= TibbrIntegration.get_all_message_data(message['id'])['messages']
      #  end
      #end  unless @messages.blank?
    else
      product = Product.find(params[:id])
      subject_string = product.subject_name
      underscored_url_string = params[:url].gsub(/[^a-zA-Z0-9]/,'_')
      page_hash = params[:hash].blank? ? '' : "_#{params[:hash]}"
      subject = TibbrIntegration.find_or_create_subject_by_name("#{subject_string}.#{underscored_url_string}#{page_hash}")
      if subject
        @messages = TibbrIntegration.get_messages_on_subject("#{subject_string}.#{underscored_url_string}#{page_hash}")
        @active_tab = 'tib-post_tib-box'
        unless  @messages.blank?
          @messages.map do |message|
            if message['messages'].count == 2
              message['messages']= TibbrIntegration.get_all_message_data(message['id'])['messages']
            end
          end
        else
          @messages = []
        end
      end
    end
    set_previous_url
  end

  def destroy_post
    TibbrIntegration.delete_message(params[:id])
    response = "var redirect_url='#{get_previous_url}'"
    render :js => response, :status => :ok
  end
  def set_previous_url
    session[:prev_url] = request.request_uri
  end

  def get_previous_url
    session[:prev_url]
  end

end