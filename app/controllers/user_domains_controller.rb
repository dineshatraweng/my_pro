class UserDomainsController < ApplicationController
  before_filter  :require_admin
  before_filter :authenticate_domains_access, :except => [ :authentication, :authenticate ]
  def index
    @user_domains = []
    @alphabets = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']
    @search_char = params[:search]
    unless params[:search].blank?
      @user_domains =  UserDomain.where("user_domains.name like ?", "#{params[:search]}%").includes(:user_groups)
    else
      @user_domains = UserDomain.where("name like ?", "A%").includes(:user_groups)
    end
  end

  def show
    @domain = UserDomain.find(params[:id])
    groups = @domain.user_groups
    @group_name = []
    groups.each do |g|
      @group_name.push(g.name)
    end
  end

  def new
    @user_domain = UserDomain.new
  end


  def create
    @user_domain = UserDomain.new(params[:user_domain])
    if @user_domain.save
      redirect_to user_domains_path(:search => @user_domain.name[0])
    else
      render 'new'
    end
  end

  def edit
    @user_domain = UserDomain.find(params[:id])
  end

  def update
    @user_domain = UserDomain.find(params[:id])
    if @user_domain.update_attributes(params[:user_domain])
      redirect_to user_domains_path(:search => @user_domain.name[0])
    else
      render 'edit'
    end
  end

  def destroy
    @user_domain = UserDomain.find(params[:id])
    @user_domain.destroy
    redirect_to user_domains_path(:search => @user_domain.name[0])
  end

  def authentication

  end

  def authenticate
    @authentication_data = params[:authenticate]
    email     = @authentication_data[:email]
    password  = @authentication_data[:password]

    @error_message  = "Authentication Failed. "
    @email_error    = email.blank?
    @password_error = password.blank?
    if email.blank? || password.blank?
      render 'authentication'
    else
      if UserDomain.authenticate_access(@authentication_data)
        session[:user_domain_auth_email] =  @authentication_data[:email]
        redirect_back_or_default
      else
        @error_message += "Please enter correct credentials"
        render 'authentication'
      end
    end
  end
end
