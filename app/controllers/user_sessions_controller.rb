class UserSessionsController < ApplicationController
  before_filter :set_cache_buster

  def new
    if logged_in?
      redirect_to root_url
    else
      @user_session = UserSession.new
    end
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      cookies["tibco-docs-login"] = {:value => true,
                                     :expires => 30.minutes.from_now}
      session.delete(:this_url)
      user_session = {'username' => @user_session.attempted_record.username, 'email' => @user_session.attempted_record.email}
      session[:user_details] = current_user
      session[:last_request_time_admin] = Time.now.utc
      redirect_to(root_url, :notice => 'Login Successful')
    else
      @user_session.generic_error
      render :action => "new"
    end
  end

  def destroy
    @user_session = UserSession.find
    unless @user_session.blank?
      @user_session.destroy
      session.delete(:this_url)
      session.delete(:user_details)
      session.delete(:last_request_time_admin)
      session.delete(:user_domain_auth_email)
      cookies.delete("tibco-docs-login")
    end
    redirect_to root_url
  end

  private
    def set_cache_buster
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
end