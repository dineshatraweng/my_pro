class ApplicationController < ActionController::Base
  before_filter :keep_xhr_request_in_session
  before_filter :set_p3p
  before_filter :check_last_requested_at

  #checking for last user request
  def check_last_requested_at
    if logged_in?
      if current_user_is_admin?
        session[:last_request_time_admin] = current_user.last_request_at if session[:last_request_time_admin].blank?
        if (Time.now.utc -   session[:last_request_time_admin])/60 > 30
          @user_session = UserSession.find
          unless @user_session.blank?
            @user_session.destroy
            session.delete(:this_url)
            session.delete(:user_details)
            session.delete(:last_request_time_admin)
            cookies.delete("tibco-docs-login")
          end
          redirect_to root_url
        else
          session[:last_request_time_admin] = current_user.last_request_at
        end
      else
        session[:last_request_time_employee] = Time.now.utc if session[:last_request_time_employee].blank?
        if (Time.now.utc -   session[:last_request_time_employee])/60 > 30
          if session.has_key?(:employee_login)
            session.delete(:employee_login)
            session.delete(:this_url)
            session.delete(:user_details)
            session.delete(:tibbr_user)
            session.delete(:login_as)
            session.delete(:last_request_time_employee)
            cookies.delete("tibco-docs-login")
            flash[:notice] = "TIBCOmmunity Logged out."
          end
          session[:product_path] = root_url
          if params[:controller] == "tibbr_integration" and params[:action] == "show"
            redirect_to get_previous_url
          elsif params[:controller] == "tibbr_integration" and params[:action] == "index"
            redirect_to root_url + "tibbr_integration?url="+ params[:url] + "&product=" + params[:product]
          else
            redirect_to(root_url)
          end
        else
          session[:last_request_time_employee] =  Time.now.utc
        end
      end
    end

  end



#this is required by IE so that we can set session cookies
  def set_p3p
    headers['P3P'] = 'CP="ALL DSP COR CURa ADMa DEVa OUR IND COM NAV"'
  end


#  protect_from_forgery

  helper_method :current_user,:current_user_details, :logged_in?, :current_user_is_admin?, :xml_parsed_to_search_results,
                :pagination_links, :current_search_url, :block_information, :get_extension_from_url, :current_user_is_employee?,
                :product_present_in_authorized_list? , :getlogin_as, :user_tib_employee?

  def getlogin_as(groups)
    return session[:login_as] unless session[:login_as].blank?
    if groups.class == Array
      valid_groups = ["TIBCO Employees", "TIBCO Customers", "TIBCO Partners"]
      groups.each do |gn|
        session[:login_as] = gn  if valid_groups.include?(gn)
      end
    else
      session[:login_as] = groups
    end
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = (current_user_session && current_user_session.record) || (Employee.new(session[:employee_login]) if session.has_key?(:employee_login))
  end

  def current_user_details
    return session[:user_details] if defined? session[:user_details]
  end

  def current_user_is_employee?
    return true if current_user.is_a?(Employee)
  end

  def current_user_is_admin?
    return true if current_user.is_a?(Admin)
  end

  def logged_in?
    return current_user ? true : false
  end

  def require_admin
    return true if (logged_in? && !current_user_is_employee?)
    redirect_to(root_url,:notice => "Unauthorized Access")
  end

  def redirect_if_logged_in
    redirect_to root_url if logged_in?
  end

  def xml_parsed_to_search_results(url)
    if url.include?("cache")
      new_url = url+"&proxystylesheet=my_frontend"
      return {:cached_page => RestClient.get(new_url)}
    else
#      output = RestClient.get(url)
#      doc = Nokogiri::XML(output)
#      xslt = Nokogiri::XSLT(File.read("#{Rails.root}/lib/default_frontend_stylesheet.xslt"))
#      return xslt.transform(doc)

#----------------------------------------------------
#  Parsing XML Manually using Nokogiri
#----------------------------------------------------
      new_output = ""
      output = RestClient.get(url)
      output.each_line{|line| new_output += line.chop}
      doc = Nokogiri::XML(new_output)
      search_result_nodes = doc.xpath('//GSP/RES')

      all_params = {}
      results = {}
      results[:actual_results] = {}

      doc.xpath('//GSP/PARAM').each do |p|
        case p['name']
          when 'q'
            all_params[:query] = p['value']
          when 'site'
            all_params[:site] = p['value']
          when 'client'
            all_params[:client] = p['value']
          when 'output'
            all_params[:output] = p['value']
          when 'start'
            all_params[:start] = p['value']
        end
      end

      results[:all_params] = all_params
      results[:filtered] = false
      results[:total_results] = 0
      results[:search_time] = doc.xpath('//GSP/TM')[0].text

      unless doc.xpath('//GSP/RES').blank?
        results[:from] = doc.xpath('//GSP/RES')[0]['SN']
        results[:to] = doc.xpath('//GSP/RES')[0]['EN']
      end

      unless search_result_nodes.blank?
        index=0
        search_result_nodes.children.each do |child|
          case child.name
            when 'M'
              results[:total_results] = child.text
            when 'NB'
              results[:top_nav] = {}
              child.children.each do |top_nav|
                case top_nav.name
                  when 'PU'
                    results[:top_nav][:previous] = top_nav.text
                  when 'NU'
                    results[:top_nav][:next] = top_nav.text
                end
              end
            when 'R'
              key = "result_#{index}".to_sym
              index+=1
              results[:actual_results][key] = {}
              results[:actual_results][key][:indented] = (child['L'].to_i > 1)
              child.children.each do |ar|
                case ar.name
                  when 'U'
                    results[:actual_results][key][:display_link] = ar.text
                  when 'UE'
                    results[:actual_results][key][:link_for_title] = URI.unescape(ar.text)
                  when 'T'
                    results[:actual_results][key][:title] = ar.text
                  when 'FS'
                    results[:actual_results][key][:date] = ar['VALUE']
                  when 'S'
                    results[:actual_results][key][:description] = ar.text
                  when 'HAS'
                    ar.children.each do |c|
                      case c.name
                        when 'C'
                          add_to_query = "#{c['CID']}:#{results[:actual_results][key][:link_for_title]}"
                          final_cached_url = "/search?q=cache:#{add_to_query}+#{all_params[:query]}&site=#{all_params[:site]}&client=#{all_params[:client]}&output=#{all_params[:output]}&proxystylesheet=my_frontend"
                          results[:actual_results][key][:cache_link] = final_cached_url
                          results[:actual_results][key][:size] = c['SZ']
                      end
                    end
                  when 'HN'
                    results[:actual_results][key][:more_results] = {}
                    results[:actual_results][key][:more_results][:text] = "More Results from #{ar.text}"
                    sitesearch_url = "/search?q=#{all_params[:query]}&site=#{all_params[:site]}&client=#{all_params[:client]}&output=#{all_params[:output]}&as_sitesearch=#{ar.text}"
                    results[:actual_results][key][:more_results][:link] = "#{root_url.chop}#{sitesearch_url}"
                end
              end
            when 'FI'
              results[:filtered] = true
          end
        end
      end
      return results
    end
  end

  def pagination_links(query,start,total_results)
    links = []
    num = start/10
    range = (num > 5) ? (num > 95 ? (90..99) : (num-5)..(num+4)) : (0..9)
    site = logged_in? ? app_config(:gsa,:collections,:emp) : app_config(:gsa,:collections,:pub)
    range.each do |n|
      if(total_results.to_i/10 >= n)
        links << {:index => n+1, :link => "/search?q=#{query}&site=#{site}&client=default_frontend&output=xml&start=#{(n*10).to_s}&filter=#{app_config(:search,:filter)}",
                  :disabled => ((num == n) ? true : false)}
      end
    end
    return links
  end

  def current_search_url(hash)
    url ""
    if logged_in?
      url = "#{root_url}search?q=#{hash[:query]}&site=#{app_config(:gsa,:collections,:emp)}&client=#{hash[:client]}&output=#{hash[:output]}&start=#{hash[:start]}&filter=#{app_config(:search,:filter)}"
    else
      url = "#{root_url}search?q=#{hash[:query]}&site=#{app_config(:gsa,:collections,:pub)}&client=#{hash[:client]}&output=#{hash[:output]}&start=#{hash[:start]}&filter=#{app_config(:search,:filter)}"
    end
    return url
  end

  def block_information
    redirect_to root_url
  end

  def get_extension_from_url(url)
    require 'uri'
    path = URI.parse(URI.encode(url.strip)).path
    return path.blank? ? '' : path.split('.').last
  end

  def product_present_in_authorized_list?(product_name)
    if current_user.is_a?(Admin)
      return true
    else
      product = Product.employee_products(product_name)
      return (product.blank? ? false : true)
    end
  end

  def logout_if_session_stale
    redirect_to logout_path if current_user_session.stale?
  end

  def keep_xhr_request_in_session
    request_url = request.url
    if session.has_key?(:this_url)
      @previous_url = session[:this_url] if request_url == root_url
    end
    if request.xhr?
      if params[:controller] == "products" and ["show","a_z_products","find"].include?params[:action]
        session[:this_url] = request_url
      end
    end
  end

  def store_product_path
    session[:product_path] = request.request_uri
  end
  def return_stored_product
    return session[:product_path] if !session[:product_path].blank?
    session[:product_path] = nil
    root_url
  end
  def store_location location=nil
    session[:return_to] = location || request.request_uri
  end

  def redirect_back_or_default(default = {})
    redirect_to(session[:return_to] || root_url )
    session[:return_to] = nil
  end

  def create_n_login_tibbr_user(logged_in_user , username)
    begin
      logged_in_user['username'] = logged_in_user['email']
      tibbr_response = TibbrIntegration.find_or_create_user(logged_in_user)
      user_authtoken = tibbr_response[0]['auth_token']
      tibbr_user = TibbrIntegration.change_user_details(tibbr_response[0],logged_in_user['first_name'],logged_in_user['last_name'])
      session[:tibbr_user] = {:id => tibbr_user["id"], :login => tibbr_user["email"], :email => tibbr_user["email"], :auth_token => user_authtoken } unless  tibbr_user.blank?
    rescue => error
      Rails.logger.info "Error occured in create_n_login_tibbr_user"
      Rails.logger.info error.class
      Rails.logger.info error.message
      Rails.logger.info error.backtrace
      logged_in_user['username_of_employee'] = username
      UserMailer.send_error_in_tibbr_mail(error,tibbr_response[1],logged_in_user).deliver
    end
  end

  def user_tib_employee?
    session['login_as'] === "TIBCO Employees"
  end

  def store_active_login_tab(value)
    session["active-tab"] = value
  end

  def del_active_login_tab
    session.delete("active-tab")
  end

  def get_active_login_tab!
    session.delete("active-tab")
  end

  def authenticate_domains_access
    if UserDomain.authenticated_emails.include?(session[:user_domain_auth_email])
      return true
    else
      store_location
      redirect_to authentication_user_domains_path
    end
  end

  def return_redirect_path(path)
    if path.starts_with?("/emp/") || path.starts_with?("emp/")
      path
    else
      "emp/#{path}"
    end
  end

end