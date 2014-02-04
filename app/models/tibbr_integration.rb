class TibbrIntegration
  require "uri"
  require "net/http"
  require "active_support"

  @@auth_token = app_config(:tibbr,:auth_token)
  @@client_key = app_config(:tibbr,:client_key)
  @@user_password = app_config(:tibbr,:user_password)

  def self.activate_user(activation_code)
    request_path = "/a/users/#{activation_code}/activate.json"
    headers = {"client_key" => @@client_key}
    data = {}
    result = self.send_request("PUT", request_path, data, headers)
    return result[:response]
  end

  def self.change_user_email(tibbr_user,new_email)
    request_path = "/a/users/#{tibbr_user['id']}.json"
    headers = {"client_key" => @@client_key,"auth_token" => tibbr_user['auth_token']}
    data = {"user[email]" => new_email}
    result = self.send_request("PUT", request_path, data, headers)
    return result[:response]
  end

  def self.change_user_details(tibbr_user,first_name,last_name)
    if tibbr_user['first_name'] != first_name || (!last_name.blank? && tibbr_user['last_name'] != last_name)
      request_path = "/a/users/#{tibbr_user['id']}.json"
      headers = {"client_key" => @@client_key,"auth_token" => tibbr_user['auth_token']}
      data = {"user[first_name]" => first_name, "user[last_name]" => last_name}
      result = self.send_request("PUT", request_path, data, headers)
      return result[:response]
    else
      return tibbr_user
    end
  end

  def self.login(user_deta)
    request_path = "/a/users/login.json"
    headers = {"client_key" => @@client_key}
    # data = {"params[login]" => app_config(:tibbr,:login), "params[password]" => app_config(:tibbr,:password), "params[remember_me]"=> true}
    result = self.send_request("POST", request_path, user_deta, headers)
    return result[:response]

  end

  def self.admin_login
    user_data = {"params[login]" => app_config(:tibbr,:login), "params[password]" => app_config(:tibbr,:password), "params[remember_me]" => true}
    result = self.login(user_data)
  end


  def self.user_login(user_details)
    user_group = find_group_of_user(user_details)[1]
    password = user_group.include?("TIBCO Employees") ? app_config(:tibbr,:employee_password) : app_config(:tibbr,:user_password)
    user_data = {"params[login]" => "#{user_details['email']}", "params[password]" => password , "params[remember_me]" => true}
    result = self.login(user_data)
  end

  def self.find_group_of_user(user_details)
    user_domain = user_details['email'].split('@').last
    domain = UserDomain.find_by_name(user_domain)
    valid_groups = ["TIBCO Employees", "TIBCO Customers", "TIBCO Partners"]
    valid = false
    user_group = []
    unless domain.blank?
      groups = domain.user_groups
      groups.each do |g|
        if valid_groups.include?(g.name.strip)
          valid = true
          user_group << g.name
        end
      end
    end
    return [valid,user_group]
  end


  def self.find_or_create_subject_by_name(subject_name, render_name = nil, parent_id = nil, description = nil)
    subject = self.find_subject_by_name(subject_name)
    if subject.nil?
      render_name = subject_name if render_name.blank?
      subject_details = {:name => subject_name,:render_name => render_name, :parent_id => parent_id, :description => description}
      subject = self.create_subject(subject_details)
    end
    return subject
  end

  def self.find_subject_by_name(subject_name)
    subjects = self.get_subjects(subject_name)
    if subjects
      subject = subjects["items"].select{|s| s["name"]== subject_name }.first  unless subjects.blank? && subjects.has_key?("items")
      return subject
    else
      return false
    end
  end

  def self.get_subjects(search_string = nil)
    request_path = "/a/users/1/search_subjects.json"
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    data = search_string.blank? ?  { } : {"params[page]" => 1, "params[per_page]" => 30, "params[set_actions]" => true, "params[search_str]" => search_string }
    result = self.send_request("GET", request_path, data, headers)
    return result[:response]
  end

  def self.create_subject(subject_details)
    request_path = "/a/subjects.json"
    data = {"subject[name]"           => subject_details[:name],
            "subject[render_name]"   => subject_details[:render_name],
            "subject[description]"    => subject_details[:description],
            "subject[parent_id]"      => subject_details[:parent_id],
            "subject[scope]"          => "public",
            "subject[allow_children]" => true,
            "subject[user_id]"        => 1
    }
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    result = self.send_request( "POST", request_path, data, headers)
    return result[:response]
  end

  def self.update_subject(subject_id, subject_details)
    request_path = "/a/subjects/#{subject_id}.json"
    data = {"subject[name]"           => subject_details[:name],
            "subject[render_name]"    => subject_details[:render_name],
            "subject[description]"    => subject_details[:description],
            "subject[parent_id]"      => subject_details[:parent_id]
    }
    data.delete("subject[name]") if subject_details[:name].blank?
    data.delete("subject[parent_id]") if subject_details[:parent_id].blank?
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    result = self.send_request("PUT", request_path, data, headers)
    return result[:response]
  end

  def self.delete_subject(subject_id)
    request_path = "/a/subjects/#{subject_id}/delete.json"
    data = {}
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    self.send_request( "PUT", request_path, data, headers)
  end

  def self.undelete_subject(subject_id)
    request_path = "/a/subjects/#{subject_id}/undelete.json"
    data = {}
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    self.send_request("PUT", request_path, data, headers)
  end

  def self.create_ldap_user(user = {})
    user_details = {:login => "user_tibbr_#{user['id']}",
                    :email => user['email'],
                    :first_name => user['first_name'],
                    :last_name => user['last_name'],
                    :company => user['company']
    }
    user_group =find_group_of_user(user)
    password = user_group[1].include?("TIBCO Employees") ? app_config(:tibbr,:employee_password): app_config(:tibbr,:user_password)
    user_details.merge!({:password => password})
    self.create_user(user_details)
  end

  def self.find_or_create_user(user_details = {})
    tibber_error=[]
    user = self.user_login(user_details)
    unless user['error'].blank?
      user =  self.create_ldap_user(user_details)
      tibber_error.push(user.inspect)
      user = self.user_login(user_details)
    end
    tibber_error.push(user['error'])
    return [user["json_class"] == "User" ? user : nil , tibber_error]
  end

  def self.create_user(user_details)
    request_path = "/a/users.json"
    data = {"user[password]"              => user_details[:password],
            "user[password_confirmation]" => user_details[:password],
            "user[company]"               => user_details[:company],
            "user[email]"                 => user_details[:email].to_s.strip,
            "user[first_name]"            => user_details[:first_name].to_s.strip,
            "user[last_name]"             => user_details[:last_name].blank? ? user_details[:first_name].to_s.strip : user_details[:last_name].to_s.strip,
            "user[login]"                 => user_details[:login]
    }
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
      result =  self.send_request("POST", request_path, data, headers)
    return result[:response]
  end

  def self.post_message_on_subject(message_details, subject_name, authtoken = nil)
    post_data = { :content   => "@#{subject_name} #{message_details[:content]}",
                  :user_id => authtoken
    }
    post_data.merge!({:link => message_details[:url]}) unless message_details[:url].blank?
    post_data.merge!({:parent_id => message_details[:parent_id]}) unless message_details[:parent_id].blank?
    self.post_message(post_data, authtoken)
  end

  def self.post_message(message_details,authtoken = nil)
    request_path = "/a/messages.json"
    data = { "message[content]"   => message_details[:content],
             "message[user_id]"   => message_details[:user_id]
    }
    data.merge!({"message[links[link[url]]]" => message_details[:link]}) unless message_details[:link].blank?
    data.merge!({"message[parent_id]" => message_details[:parent_id]}) unless message_details[:parent_id].blank?
    authtoken = authtoken
    headers = {"auth_token" => authtoken ,"client_key" => @@client_key}
    result =  self.send_request("POST", request_path, data, headers)
    result[:response]
  end

  def self.delete_message(message_id,authtoken = nil)
    request_path = "/a/messages/#{message_id}/delete.json"
    data = {}
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    result =  self.send_request("PUT", request_path, data, headers)
    result[:response]
  end

  def self.get_messages_on_subject(subject_name,search_string='')
    request_path = '/a/users/1/subject_messages.json'
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    #subject = self.find_subject_by_name(subject_name)
    #subject_id = subject["id"]
    #search_string= search_string.empty? ? subject["name"] : search_string
    data = {"params[page]" => 1, "params[per_page]" => 30, "params[set_actions]" => false, "params[subject_id]" => subject_name}
    result = self.send_request("GET", request_path, data, headers)
    return result[:response]['items']
  end

  def self.get_message_by_string(search_string)
    request_path = '/a/users/1/message_search.json'
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    data = {"params[page]" => 1, "params[per_page]" => 30, "params[search_str]" => search_string}
    result = self.send_request("GET", request_path, data, headers)
    return result[:response]['items']
  end

  def self.impersonate_post_message(impersonate_user_id, message_details)
    request_path = "/a/users/5/messages.json?impersonate_user_id=#{impersonate_user_id}.json"
    data = { "message[content]" => message_details[:content], "message[parent_id]" => message_datails[:parent_id] }
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    result =  self.send_request("POST", request_path, data, headers)
    result[:response]
  end

  def self.find_n_update_subject_by_name(find_by_subject_name, update_subject_name , render_name = nil, parent_id = nil)
    subject = self.find_subject_by_name(find_by_subject_name)
    unless subject.blank?
      if find_by_subject_name != update_subject_name or render_name != subject["display_name"]
        render_name = render_name.blank? ? update_subject_name : render_name
        subject_details = {:name => update_subject_name, :render_name => render_name, :parent_id => parent_id }
        subject_id = subject["id"]
        subject = self.update_subject(subject_id, subject_details)
      end
    end
    return subject
  end

  def self.create_product_subject(product)
    env_name       = app_config(:tibbr,:root_subject)
    env_parent_id  = self.find_or_create_subject_by_name(env_name)["id"]
    parent_product = product.parent
    if parent_product.blank?
      render_name  = product.slug.underscore
      subject_name = "#{env_name}.#{render_name}"
    else
      render_name  = "#{parent_product.slug.parameterize}.#{product.version_no.parameterize.underscore}"
      subject_name = "#{env_name}.#{render_name}"
      env_parent_id = self.find_or_create_subject_by_name(subject_name)["id"]
    end
    product_subject   = self.find_or_create_subject_by_name(subject_name, render_name, env_parent_id)
    unless product.new_record?
      product_parent_id = product_subject["id"]
      child_products = product.children
      unless child_products.blank? && product_parent_id.blank?
        child_products.each do |child_product|
          render_name  = "#{product.slug.underscore}.#{child_product.version_no.parameterize.underscore}"
          subject_name = "#{env_name}.#{render_name}"
          self.find_or_create_subject_by_name(subject_name, render_name, product_parent_id)
        end
      end
    end
    return product_subject
  end

#def self.create_parent_product_subject(product, env_parent_id = nil, env_name = nil )
#  if env_name.blank?
#    env_name = app_config(:tibbr,:root_subject)
#    env_parent_id = self.find_or_create_subject_by_name(env_name)["id"]
#  end
#  product_render_name = product.slug.parameterize
#  product_subject_name = "#{env_name}.#{product_render_name}"
#  parent_product_parent_id = self.find_or_create_subject_by_name(product_subject_name, product_render_name, env_parent_id)["id"]
#  child_products = product.children
#  unless child_products.blank? && parent_product_parent_id.blank?
#    child_products.each do |child_product|
#      subject = self.create_non_parent_prod_subject(product, child_product, parent_product_parent_id, env_name = nil)
#      #child_product_subject_name = "#{env_name}.#{parent_product.slug.parameterize}.#{child_product.version_no.parameterize}"
#      #child_product_render_name = "#{parent_product.slug.parameterize} #{child_product.version_no.parameterize}"
#      #sub_subject = self.find_or_create_subject_by_name(child_product_subject_name, child_product_render_name, parent_product_parent_id)
#    end
#  end
#end

  def self.get_all_message_data(message_id)
    request_path = "/a/messages/#{message_id}.json"
    headers = {"auth_token" => @@auth_token ,"client_key" => @@client_key}
    result =  self.send_request('GET', request_path, {}, headers)
    result[:response]
  end

  def self.update_product_subject_by_name(prev_subject_name, product, env_name = nil)
    env_name = app_config(:tibbr,:root_subject) if env_name.blank?
    parent_product = product.parent
    if parent_product.blank?
      render_name  =  product.slug.underscore
      subject_name =  "#{env_name}.#{render_name}"
      find_name    =  "#{env_name}.#{prev_subject_name}"
      parent_id    =  self.find_or_create_subject_by_name(env_name)["id"]
    else
      render_name   =  "#{parent_product.slug.underscore}.#{product.version_no.parameterize.underscore}"
      #subject_name =  "#{env_name}.#{parent_product.slug.parameterize}.#{product.name.split(" ").last.parameterize}"
      subject_name  =  "#{env_name}.#{render_name}"
      find_name     =  "#{env_name}.#{parent_product.slug.underscore}.#{prev_subject_name}"
      parent_prod_sub_name = "#{env_name}.#{parent_product.slug.underscore}"
      parent_id     =   self.find_or_create_subject_by_name(parent_prod_sub_name)["id"]
    end
    subject = self.find_n_update_subject_by_name(find_name, subject_name, render_name)
    if subject.blank?
      subject_details = {:name => subject_name,:render_name => render_name, :parent_id => parent_id }
      subject = self.create_subject(subject_details)
    end
    subject_parent_id = subject["id"]
    child_products    = product.children
    unless child_products.blank?
      child_products.each do |child_product|
        render_name   = "#{product.slug.underscore}.#{child_product.version_no.parameterize.underscore}"
        #subject_name = "#{env_name}.#{parent_product.slug.parameterize}.#{product.name.split(" ").last.parameterize}"
        subject_name  = "#{env_name}.#{render_name}"
        find_name     = "#{env_name}.#{render_name}"
        child_subject = self.find_n_update_subject_by_name(find_name, subject_name, render_name)
        if child_subject.blank?
          subject_details = {:name => subject_name,:render_name => render_name, :parent_id => subject_parent_id }
          child_subject   = self.create_subject(subject_details)
        end
      end
    end
    return subject
  end

##---------------------------------------------------------------------------------------------------------------------
  def self.sync_with_tibbr
    parent_products      = Product.all.select{|p| p.is_parent_product?}
    unversioned_products = Product.all.select{|p| p.is_unversioned_product?}
    env_name      =  app_config(:tibbr,:root_subject)
    env_parent_id = self.find_or_create_subject_by_name(env_name)["id"]

    unless unversioned_products.blank?
      unversioned_products.each do |unversioned_product|
        puts unversioned_product.name
        unversioned_render_name  = unversioned_product.slug.parameterize
        unversioned_subject_name = "#{env_name}.#{ unversioned_render_name}"
        subject =  self.find_or_create_subject_by_name(unversioned_subject_name, unversioned_render_name, env_parent_id)
       # unless subject['name'].blank?
          unversioned_product.update_attributes(:subject_name => unversioned_subject_name)
      #  end
      end
    end
    unless parent_products.blank?
      parent_products.each do |parent_product|
        puts parent_product.name
        product_render_name = parent_product.slug.parameterize
        product_subject_name = "#{env_name}.#{product_render_name}"
        parent_subject = self.find_or_create_subject_by_name(product_subject_name, product_render_name, env_parent_id)
      #  unless parent_subject.blank?
          parent_product_parent_id  = parent_subject['id']
          parent_product.update_attributes(:subject_name => product_subject_name)
       # end
        child_products = parent_product.children
        unless child_products.blank? && parent_product_parent_id.blank?
          child_products.each do |child_product|
            puts child_product.name
            child_product_render_name = "#{parent_product.slug.parameterize}.#{child_product.version_no.parameterize}"
            child_product_subject_name = "#{env_name}.#{child_product_render_name}"
            sub_subject = self.find_or_create_subject_by_name(child_product_subject_name, child_product_render_name, parent_product_parent_id)
            #puts " subject: #{sub_subject.inspect} "
          #  unless sub_subject.blank?
              child_product.update_attributes(:subject_name => child_product_subject_name)
          #  end
          end
        end
      end
    end
  end

#---------------------------------------------------------------------------------------------------------------------
  def self.send_get_request(request_domain,path,data,headers=nil)
    uri = URI.parse(request_domain)
    http = Net::HTTP.new(uri.host, uri.port)
    if headers == nil
      response = http.send_request('GET',path,data)
    else
      response = http.send_request('GET',path,data,headers)
    end
    response.body
  end

  def self.send_post_request(request_domain,path,data,headers=nil)
    uri = URI.parse(request_domain)
    http = Net::HTTP.new(uri.host, uri.port)
    if headers == nil
      response = http.send_request('POST',path,data)
    else
      response = http.send_request('POST',path,data,headers)
    end
    response.body
  end

  def self.send_put_request(request_domain,path,data,headers=nil)
    uri = URI.parse(request_domain)
    http = Net::HTTP.new(uri.host, uri.port)
    if headers == nil
      response = http.send_request('PUT',path,data)
    else
      response = http.send_request('PUT',path,data,headers)
    end
    response.body
  end

  def self.send_delete_request(request_domain,path,data,headers=nil)
    uri = URI.parse(request_domain)
    http = Net::HTTP.new(uri.host, uri.port)
    if headers == nil
      response = http.send_request('DELETE',path,data)
    else
      response = http.send_request('DELETE',path,data,headers)
    end
    response.body
  end

  def self.send_request(request_type, request_path, data={}, headers={})
    domain = app_config(:tibbr,:host_domain)        # initializing host domain for sending request
    request_path = "/#{request_path}" unless request_path[0] == "/"
    data = data.to_query if data.is_a?(Hash)
    response = {}
    begin
      if request_type == "GET"
        response = send_get_request(domain, request_path, data, headers)
      elsif request_type == "POST"
        response = send_post_request(domain, request_path, data, headers)
      elsif request_type == "PUT"
        response = send_put_request(domain, request_path, data, headers)
      elsif request_type == "DELETE"
        response = send_delete_request(domain, request_path, data, headers)
      end
      return  {:response => ActiveSupport::JSON.decode(response)}
    rescue Exception => e
      details = {"request_path" => request_path, "data" => data}
      UserMailer.send_error_in_tibbr_mail(e,details).deliver
      return {:response => false}
    end
  end
end