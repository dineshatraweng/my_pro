class LdapLoginsController < ApplicationController
  before_filter :redirect_if_logged_in, :only => [:new,:login]

  require "#{Rails.root}/lib/ldap_connector.rb"
  def new
    @success = {:active_tab => "partners-and-customers-login"}
    active_tab = get_active_login_tab!
    @success = {:active_tab => active_tab } unless active_tab.blank?
  end


  def login
    url = app_config(:tibcommunity,:authentication_url)
    @success = {}
    begin
      data = RestClient.post(url,{:params => {:login => params[:ldap_credentials][:username],:password => params[:ldap_credentials][:password]}})
      @success = ActiveSupport::JSON.decode(data)
      @success[:active_tab] = params[:ldap_credentials][:active_tab]
    rescue => e
      Rails.logger.info "Exception Occurred"
      Rails.logger.info e.class
      Rails.logger.info e.message
    end
    if @success.blank?
      @success = {}
      @success[:error] = "Username or Password is invalid."
      render :action => 'new'
    else
      if @success['authenticated'] == false
        @success[:error] = "Username or Password is invalid."
        render :action => 'new'
      else
        if valid_user_group?
          session.delete(:this_url)
          session[:employee_login] = {"name"=>@success['display_name'], "email"=>@success['email']}
          session[:last_request_time_employee] = Time.now.utc
          cookies["tibco-docs-login"] = {:value => true}
          #create_n_login_tibbr_user(@success , params[:ldap_credentials][:username])
          if !session[:redirected_to_document].blank?
            redirect_here = session[:redirected_to_document]
            session.delete(:redirected_to_document)
            redirect_to root_url+ return_redirect_path(redirect_here)
          elsif params[:ldap_credentials][:redirect_url].blank? || session[:this_url] == session[:redirect_after_login]
            redirect_to return_stored_product
          else
            redirect_to root_url+ return_redirect_path(params[:ldap_credentials][:redirect_url])
          end
        else
          @success[:error] = "You do not have permissions."
          render :action => 'new'
        end

      end
    end

#    redirect_to root_url
  end

  def logout
    if session.has_key?(:employee_login)
      session.delete(:employee_login)
      session.delete(:this_url)
      session.delete(:user_details)
      session.delete(:user_domain_auth_email)
      session.delete(:tibbr_user)
      session.delete(:login_as)
      cookies.delete("tibco-docs-login")
      flash[:notice] = "TIBCOmmunity Logged out."
    end
    session[:product_path] = root_url
    redirect_to(root_url)
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
end

