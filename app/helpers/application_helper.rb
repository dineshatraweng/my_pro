#encoding: utf-8
module ApplicationHelper
  def nested_groups(groups)
    groups.map do |group, sub_groups|
      "<li>" + render(group) + content_tag(:div, nested_groups(sub_groups), :class => "nested_groups") + "</li>"
    end.join.html_safe
  end

  def nested_comments(comments)
    comments.map do |comment, sub_comments|
      "<li>" + render(comment) + content_tag(:div, nested_comments(sub_comments), :class => "nested_comments") + "</li>"
    end.join.html_safe
  end

  def delete_function(message="")
    message ||= "Are you sure you want to delete?"
    "if (confirm('#{message}')) { var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;var m = document.createElement('input'); m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); f.appendChild(m);var s = document.createElement('input'); s.setAttribute('type', 'hidden'); s.setAttribute('name', 'authenticity_token'); s.setAttribute('value', '#{form_authenticity_token}'); f.appendChild(s);f.submit(); };return false;"
  end

  def get_document_link(product,document)
    if document.is_doctype_folder_path?
      document_link(product,document.link)
    elsif document.is_doctype_windows?
      win_document_link(product, document)
    end
  end

  def win_document_link(product, document)
    document_path = document.link
    if product.is_public_level? && product.published
      get_doc_proxy_url("/#{app_config(:path,:public)}", document_path)
    else
      get_doc_proxy_url("/#{app_config(:path,:employee)}", document_path)
    end
  end

  def public_win_document_link(product, document)
    document_path = document.link
    root_url + get_doc_proxy_url("/#{app_config(:path,:public)}", document_path).gsub("//","/")
  end

  def get_doc_proxy_url(access_level_path, url)
    access_level_path + "/#{app_config(:docs,:proxy_path)}/"+ url
  end

  def document_link(product,document_path)
    if document_path.split('.').last == 'html' || document_path.split('.').last == 'htm'
      if product.is_public_level? && product.published
        @actual_document_links.push("/#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}")
        return "#{tibbr_integration_index_url}?url=#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}&product=#{product.id}"  #if File.file?("#{root_url}#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}")
      else
        @actual_document_links.push("/#{app_config(:path,:employee)}/#{product.folder_path}/#{document_path}")
        return "#{tibbr_integration_index_url}?url=#{app_config(:path,:employee)}/#{product.folder_path}/#{document_path}&product=#{product.id}"  #if File.file?("#{root_url}#{app_config(:path,:employee)}/#{product.folder_path}/#{document_path}")
      end
    else
      if product.is_public_level? && product.published?
        return "/#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}" #if File.file?("#{root_url}#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}")
      else
        return "/#{app_config(:path,:employee)}/#{product.folder_path}/#{document_path}" #if File.file?("#{root_url}#{app_config(:path,:employee)}/#{product.folder_path}/#{document_path}")
      end
    end
  end

  def get_public_document_link(product,document)
    pub_link = ""
    if document.is_doctype_folder_path?
      pub_link = public_document_link(product,document.link)
    elsif document.is_doctype_windows?
      pub_link = public_win_document_link(product, document)
    end
    pub_link = URI.encode  pub_link # encode the url ,escape special characters
    uri_pub_link = URI pub_link
    uri_pub_link.path = clean_slashes_from_path(uri_pub_link.path)
    uri_pub_link.to_s
  end


  def clean_slashes_from_path(path)
    if path.include?("//")
      path.gsub!("//","/")
      clean_slashes_from_path(path)
    else
      return path
    end
  end

  def public_document_link(product,document_path)
    path = "#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}"
    return "#{root_url}#{path}" #if File.file?("#{root_url}#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}")
  end


  def document_link_crawl(product,document_path)
    if product.is_public_level?
      return "#{root_url}#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}" #if File.file?("#{root_url}#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}")
    else
      return "#{root_url}#{app_config(:path,:employee)}/#{product.folder_path}/#{document_path}" #if File.file?("#{root_url}#{app_config(:path,:employee)}/#{product.folder_path}/#{document_path}")
    end
  end

  def get_document_link_crawl(product, document)
    return "" if document.blank?
    if document.is_doctype_windows?
      win_document_link_crawl(product, document.link)
    else
      document_link_crawl(product,document.link)
    end
  end

  def win_document_link_crawl(product, document_path)
    if product.is_public_level?
      return "#{root_url}#{app_config(:path,:public)}/#{app_config(:docs,:proxy_path)}/#{document_path}" #if File.file?("#{root_url}#{app_config(:path,:public)}/#{product.folder_path}/#{document_path}")
    else
      return "#{root_url}#{app_config(:path,:employee)}/#{app_config(:docs,:proxy_path)}/#{document_path}" #if File.file?("#{root_url}#{app_config(:path,:employee)}/#{product.folder_path}/#{document_path}")
    end
  end

  def product_exists_in_group_hierarchy?(group)
    unless group.products.blank?
      return true
    end
    children = group.descendants
    children.each do |child|
      unless child.products.blank?
        return true
      end
    end
    return false
    #arr = (group.products.blank? ? true : false)
    #return true if arr == false
    #children = group.children
    #children.each do |child|
    #  arr = (child.products.blank? ? true : false)
    #  return true if arr == false
    #  product_exists_in_group_hierarchy?(child)
    #end
    #return true
  end

  #def show_valid_group_in_hierarchy(group,admin=false)
  #  return true if admin
  #  arr=[]
  #  group.products.each do |p|
  #    arr << p
  #  end
  #  group.children.each do |c|
  #    c.products.each do |p|
  #      arr << p
  #    end
  #  end
  #  ret_arr=[]
  #  arr.each do |a|
  #    ret_arr << product_present_in_authorized_list?(a.name)
  #  end
  #  return true if ret_arr.include?(true)
  #end

  def get_redirect_url
    return session[:return_to] if !session[:return_to].blank?
    return session[:return_to] = root_url
    return root_url
  end

  def set_access_icon(product)
    if (product.is_public_level?)
      return "bullets green-arrow"
    elsif (product.is_employee_level?)
      return "bullets yellow-arrow"
    else
      return "bullets red-arrow"
    end
  end

  def set_access_flag(product)
    if (product.is_public_level?)
      return "Open to the Public"
    elsif (product.is_employee_level?)
      return "Requires Login"
    else
      return "Admins Only"
    end
  end

  def show_document_if_link_exists?(document)
    return true if  current_user_is_admin?
    return link_is_broken?(document)

  end

  def link_is_broken?(document)
    if document.doctype == Document::DOCTYPE[:windows]
      link_is_broken_on_win_ftp?(document)
    elsif document.doctype == Document::DOCTYPE[:folder_path]
      link_is_broken_on_ftp_root?(document)
    end
  end

  def link_is_broken_on_ftp_root?(document)
    logger.info "~~~~~~~~~~~~~~checking for broken link~~~~~~~~~~~~~~~~~~~~~~"
    logger.info "#{app_config[:ftp_root]}/#{document.product.folder_path}/#{document.link}"
    logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    File.exists?("#{app_config[:ftp_root]}/#{document.product.folder_path}/#{document.link}")
  end

  def link_is_broken_on_win_ftp?(document)
    logger.info "~~~~~~~~~~~~~~checking for broken link in Windows Server FTP~~~~~~~~~~~~~~~~~~~~~~"
    logger.info "#{app_config[:win_ftp_root]}/#{document.link}"
    logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    File.exists?("#{app_config[:win_ftp_root]}/#{document.link}")
  end

  def is_zip_present?(product,zip_file)
    logger.info "~~~~~~~~~~~~~~~zip file~~~~~~~~~~~~~~~~~~~~~"
    logger.info "#{app_config[:ftp_root]}/#{product.folder_path}/#{zip_file}"
    logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    File.exists?("#{app_config[:ftp_root]}/#{product.folder_path}/#{zip_file}")
  end

  def display_document_icon(dt)
    File.exists?("#{Rails.root}/public/images/#{dt.downcase}.png") ?  "/images/#{dt.downcase}.png" :  "/images/default.png"
  end

  def has_a_valid_document_link(documents)
    documents.each do |doc|
      return true if link_is_broken?(doc)
    end
    return false
  end
  def get_product_id(product)
    if product.is_parent_product?
      return product.id if current_user_is_admin?
    else
      if product.is_unversioned_product?
        return product.id
      elsif product.is_child_product?
        return product.parent.id
      end
    end
  end

  def get_category_id(product)
    if product.is_parent_product?
      return product.groups.first.name.parameterize.to_json if current_user_is_admin?
    else
      if product.is_unversioned_product?
        return product.groups.first.name.parameterize.to_json
      elsif product.is_child_product?
        return product.parent.groups.first.name.parameterize.to_json
      end
    end
  end

  def get_extracted_version(product)
    return product.name.split(" ").last
  end

  def get_formatted_description(product)
    RedCloth.new(sanitize(product.description),[:filter_html, :filter_styles, :filter_classes, :filter_ids] ).to_html.html_safe
  end

  def user_logout_path
    if current_user_is_admin?
      return logout_url
    else
      return logout_ldap_logins_url
    end
  end

  def greeting
    if logged_in?
      return "Welcome, #{current_user_details['username']}"
    else
      return "Welcome Guest"
    end
  end

  def show_audit_entry?(entry)
    entry.modified_attributes.split(',').sort != ["updated_at"]
  end

  def get_formatted_audit(entry)
    get_visibility = lambda do |public,visible|
      # only for product audits
      return "Open to Public" if public && visible
      return !public && visible ? "Requires Login" : "Admin Only"
    end
    payload_json = ActiveSupport::JSON.decode(entry.payload_json)
    name = payload_json['name']
    type_of_payload = entry.payload_type
    ftp_path = entry.payload_type == 'Product'? payload_json['folder_path'] : payload_json['link']
    visibility = entry.payload_type == 'Product'? get_visibility.call(payload_json['public'],payload_json['visible']) : "Not Applicable"
    user = entry.user_id
    modified_on = entry.created_at.strftime("%m/%d/%Y at %I:%M%p")
    return {:type_of_payload => type_of_payload,:name => name,:ftp_path => ftp_path, :visibility => visibility, :user => user, :modified_on => modified_on}
  end

  def get_admin_username(key_map,id)
    return key_map.select{|hash| hash['username'] if hash['id']== id}.first['username']
  end

  def show_delete_comment_link(comment)
    if logged_in? && current_user_is_employee?
      delete_tag = '  | <a class="delete-comment-link" title="Delete this reply" href="#" name="'+ comment['id'].to_s+'">Delete</a> <p class="confirm-delete hidden"><span class="confirm-msg">Are you sure you want to delete this comment?</span><a class="yes btn accept-del-comment" href="#">Yes</a> <a href="#" class="cancel-btn cancel-button-comment">Cancel</a></p>'
      return session[:tibbr_user] && comment['user']['email'] == session[:tibbr_user][:email]? delete_tag.html_safe : ""
    else
      return ""
    end
  end
  def show_delete_reply_link(comment)
    if logged_in? && current_user_is_employee?

      delete_tag = '  | <a class="delete-reply-link" title="Delete this reply" href="#" name="'+ comment['id'].to_s+ '">Delete</a> <p class="confirm-delete hidden"><span class="confirm-msg">Are you sure you want to delete this reply?</span><a class="yes btn accept-del-reply" href="#">Yes</a> <a href="#" class="cancel-btn cancel-button-reply">Cancel</a> </p>'
      return session[:tibbr_user] && comment['user']['email'] == session[:tibbr_user][:email]? delete_tag.html_safe : ""
    else
      return ""
    end
  end

  def show_tibbr_username(first_name, last_name)
    if first_name == last_name || last_name == 'lname'
      return "#{first_name}"
    else
      return "#{first_name} #{last_name}"
    end
  end

  def bold_search_letter(char, search_char)

    "bold-letter" if char == search_char.upcase unless search_char.blank?
  end

  def get_user_groups
    UserGroup.where("id in (?)",[1000,1001,1002])
  end

  def apply_entity_class_for_actions
    actions = ["new", "new_parent", "create", "create_parent", "edit", "edit_parent", "update", "update_parent", "authentication", "authenticate" ]
    (actions.include?(action_name) || ["doc_ftps"].include?(controller_name)) ? "entity" : ""
  end

  def get_doctype_options
    Document::DOCTYPE.collect{|k,v| [v.gsub(/_/, " "), v]}
  end

  #get the document name in product show page
  def get_document_name(document_name)
    document_name.gsub("®".force_encoding('utf-8'),"<sup>®</sup>").gsub('&reg;',"<sup>®</sup>").gsub("&REG;","<sup>®</sup>").gsub('&reg',"&amp;reg").gsub('&REG',"&amp;REG")
  end

  def add_link_broken_class(document)
    "link-broken" if current_user_is_admin? && !link_is_broken?(document)
  end


end
