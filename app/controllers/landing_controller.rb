class LandingController < ApplicationController
  before_filter :authorized_ip_or_admin?, :only => [:employee]


  def search
    params.delete(:action)
    params.delete(:controller)
    params[:q] = params[:q].sub(" ","+")
    values = params.map{|k,v| "#{k}=#{v}"}.join('&')
    url="#{app_config(:gsa,:url)}/search?#{values}"
    @search_result = xml_parsed_to_search_results(URI.escape(url))
    render 'products/search', :layout => false
  end

  def employee
    if current_user_is_admin?
      all_products = Product.all
      @products = all_products.select{ |product| !product.is_parent_product? }
    else
      all_products = Product.employee_products
      @products = all_products.select{ |product| !product.is_parent_product? && product.published }
    end
    render "documents", :layout => false
  end

  def public
    all_products = Product.all(:conditions => {:public => true,:visible => true , :published => true})
    @products = all_products.select{ |product| !product.is_parent_product?}
    render "documents", :layout => false
  end

  def folder_path
    if request.xhr?
      starting_path = params[:term]
      sep=File::SEPARATOR
      params[:term] = params[:term].gsub("\\","/")
      arr=params[:term].split(sep)
      arr.delete(".")
      arr.delete("..")
      ends_with_slash = params[:term].ends_with?("/") ? true : false
      list=[]

      #unless arr.blank?
        if params[:path_for] == "products"
          if Dir.chdir("#{app_config(:ftp_root)}#{sep}")
            glob_value = ends_with_slash ? "#{arr.join(sep)}/*" : "#{arr.join(sep)}*"
            count = starting_path.count "/"
            glob_value = "#{starting_path.split("/").last}*" if count == 1  and starting_path[0] == "/"
            #list=Dir.glob(glob_value)
            glob_value_dc  = glob_value.downcase
            glob_value_cc = glob_value.camelcase.split("::").join("/")
            glob_value_uc  = glob_value.upcase
            list=Dir.glob(glob_value_dc)
            list=list+Dir.glob(glob_value_cc)
            list=list+Dir.glob(glob_value_uc)
          end
        elsif params[:path_for] == "documents"
          if params[:doctype] == Document::DOCTYPE[:windows]
            list = get_win_server_folder_path(ends_with_slash, starting_path, arr,sep)
          else
            product=Product.find(params[:product_id])
            if Dir.chdir("#{app_config(:ftp_root)}#{sep}#{product.folder_path}")
              glob_value = ends_with_slash ? "#{arr.join(sep)}/*" : "#{arr.join(sep)}*"
              count = starting_path.count "/"
              glob_value = "#{starting_path.split("/").last}*" if count == 1  and starting_path[0] == "/"
              #list=Dir.glob(glob_value)
              glob_value_dc  = glob_value.downcase
              glob_value_cc = glob_value.camelcase.split("::").join("/")
              glob_value_uc  = glob_value.upcase
              list=Dir.glob(glob_value_dc)
              list=list+Dir.glob(glob_value_cc)
              list=list+Dir.glob(glob_value_uc)
            end
          end
        end
      #end
      list = list.uniq
      render :text => list.slice(0,15).to_json
    else
      block_information
    end
  end

##------------------------------------Added Functionality-------------------

  def authorize_tc_login
    logger.info("***********************************started authorize_tc_login************************************************")
    if logged_in? and current_user_is_admin?
      logger.info("*********************************user is admin*************************************************************")
      @user_session = UserSession.find
      unless @user_session.blank?
        logger.info("*******************************deleting user*************************************************************")
        @user_session.destroy
        cookies.delete("tibco-docs-login")
      end
    end
    logger.info("**********************************authorize key******************************************************")
    logger.info(params[:tc_data])
    decrypt_tc_data(params[:tc_data])
#    session[:employee_login] = params[:tc_data]
    logger.info("*****************************************calling root_url path************************************************") ;
    redirect_to root_url
  end

  def  change_user_email
    response = TibbrIntegration.user_login({ 'userGroupNames' => params[:groupname], 'username' => "user_#{params[:id]}"})
    if response['error'].blank?
      response = TibbrIntegration.change_user_email(response,params[:to_email].strip)
      unless response.has_key?('errors')
        render :text => "Your email has been updated."
      else
        render :text => "Failed to update your email(Tibbr error:#{response['errors']['error']})"
      end
    else
      render :text => "Failed to update your email(Tibbr error:#{response['error']})"
    end

  end

  private
  def authorized_ip_or_admin?
    return true if (app_config(:authorized_ips).split(',').include?(request.remote_ip) || current_user.is_a?(Admin))
    block_information
  end

  def decrypt_tc_data(encoded_string)
    logger.info("******************************started decrypt_tc_data**************************************************")
    encoded_string = encoded_string.gsub(/[ ]/,'+')
    encrypted = Base64.decode64(encoded_string.strip)
    decipher = OpenSSL::Cipher::Cipher.new("AES-128-ECB")
    decipher.decrypt
    decipher.key = app_config(:tibcommunity,:key)
    #decipher.key = key = Digest::SHA2.digest(app_config(:tibcommunity,:key))
    d = decipher.update(encrypted) + decipher.final
    arr = d.split(',')
    session_hash={}
    arr.each do |a|
      unless a.blank?
        x = a.split(':')
        session_hash[x[0]] = x[1]
      end
    end
    logger.info("*************************the value of session hash*************************************************")
    logger.info(session_hash)
    session[:employee_login] = session_hash
    cookies["tibco-docs-login"] = {:value => true}
    logger.info("*****************session and cookie values set*********************************************************")
    begin

      logger.info("**********************************************inside begin************************************************")
      logged_in_user = session_hash
      userdetails_in_xml = RestClient.get('https://docs.tibco:d0csd0tt1bc0@www.tibcommunity.com/rpc/rest/userService/usersByEmail/'+logged_in_user['email'])
      logger.info("***************************************Restclient user details******************************************")
      userdetails_hash = Hash.from_xml(userdetails_in_xml)
      logger.info(userdetails_hash)
      usergroups_in_xml = RestClient.get('https://docs.tibco:d0csd0tt1bc0@www.tibcommunity.com//rpc/rest/groupService/userGroupNames/'+ userdetails_hash['getUserByEmailAddressResponse']['return']['ID'])
      usergroups_hash = Hash.from_xml(usergroups_in_xml)
      logger.info("********************************************usergroups in hash**********************************")
      logger.info(usergroups_hash)
      logged_in_user['userGroupNames'] = []
      logged_in_user['userGroupNames'] = usergroups_hash['getUserGroupNamesResponse']['return']
      #if logged_in_user['userGroupNames'].include?('TIBCO Employees')
      #  username = logged_in_user['username'] == logged_in_user['email'] ? logged_in_user['email'].split('@').first : userdetails_hash['getUserByEmailAddressResponse']['return']['username']
      #elsif logged_in_user['userGroupNames'].include?('TIBCO Customers')
      #  username  = userdetails_hash['getUserByEmailAddressResponse']['return']['username']+ '_customer'
      #else
      #  #for TIBCO Partners
      #  username  = userdetails_hash['getUserByEmailAddressResponse']['return']['username']+ '_partner'
      #end
      logged_in_user['username'] = "user_#{userdetails_hash['getUserByEmailAddressResponse']['return']['ID']}"
      name = userdetails_hash['getUserByEmailAddressResponse']['return']['name']
      name_array = name.split(' ')
      if name_array.length > 1
        logged_in_user['first_name'] = name_array.first
        logged_in_user['last_name'] = name_array.slice(1,name_array.length-1).join(' ')
        logged_in_user['name'] =  logged_in_user['first_name'] + " "  + logged_in_user['last_name']
      else
        logged_in_user['first_name'] = name_array.first
        logged_in_user['last_name'] = name_array.first
        logged_in_user['name'] =  logged_in_user['first_name']
      end
      valid_groups = ["TIBCO Employees", "TIBCO Customers", "TIBCO Partners"]
      session[:login_as] = ""
      if valid_groups.include?(logged_in_user['userGroupNames'])
        session[:login_as] = logged_in_user['userGroupNames']
      end
      tibbr_response = TibbrIntegration.find_or_create_user(logged_in_user)
      logger.info("****************printing tibbr_response*************************************************")
      logger.info(tibbr_response.inspect)
      user_authtoken = tibbr_response[0]['auth_token']
      logger.info("*******************************calling change user details************************************************")
      tibbr_user = TibbrIntegration.change_user_details(tibbr_response[0],logged_in_user['first_name'],logged_in_user['last_name'])
      logger.info(tibbr_user.inspect)
      session[:tibbr_user] = {:id => tibbr_user["id"], :login => tibbr_user["login"], :email => tibbr_user["email"], :auth_token => user_authtoken } unless  tibbr_user.blank?
    rescue => error
      logger.info("************************An error has occured while evaluating decrypt_tc_data****************************************************")
      logged_in_user['username_of_employee'] = logged_in_user['username']
      UserMailer.send_error_in_tibbr_mail(error,tibbr_response[1],logged_in_user).deliver
    end
  end


  ##------------------------------------Added Functionality-------------------
  ## private functions
  private
  ## document name auto-complete for windows server
  def get_win_server_folder_path(ends_with_slash,starting_path,arr,sep)
    list = []
    if Dir.exists?(app_config(:win_ftp_root)) && Dir.chdir(app_config(:win_ftp_root))
      glob_value = ends_with_slash ? "#{arr.join(sep)}/*" : "#{arr.join(sep)}*"
      count = starting_path.count "/"
      glob_value = "#{starting_path.split("/").last}*" if count == 1  and starting_path[0] == "/"
      #list=Dir.glob(glob_value)
      glob_value_dc  = glob_value.downcase
      glob_value_cc = glob_value.camelcase.split("::").join("/")
      glob_value_uc  = glob_value.upcase
      list=Dir.glob(glob_value_dc)
      list=list+Dir.glob(glob_value_cc)
      list=list+Dir.glob(glob_value_uc)
    end
    return list
  end




end