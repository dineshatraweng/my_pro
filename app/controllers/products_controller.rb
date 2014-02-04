# encoding: utf-8
class ProductsController < ApplicationController
  before_filter :require_admin, :except => [:index, :show, :search, :find, :search_tab, :a_z_products, :feedback, :suggest, :fill_product_find]
  before_filter :init_controller
  require "nokogiri"
  require 'uri'
  require 'pdf/reader'
  require 'tmpdir'
  class PageReceiver
    attr_accessor :pages
    # Called when page parsing ends
    def page_count(arg)
      @pages = arg
    end
  end

  def fill_product_find
    all_products = Product.all
    products =  logged_in? && current_user_is_admin? ? all_products.select{|product| !product.is_child_product?} : all_products.select{|product| !product.is_child_product? && product.visible? && product.published? && product.check_published }
    json_array = []
    special = "-()/@"
    regex = /[#{special.gsub(/./){|char| "\\#{char}"}}]/
    products.each do |product|
      filter_name = product.filtered_name
      unless  product.filtered_name =~ regex
        json_array << {:value => product.filtered_name, :link => product_path(product), :name => product.filtered_name}
      else
        json_array << {:value => product.filtered_name, :link => product_path(product), :name => product.filtered_name}
        name = filter_name.gsub(/([\/@()-])/, '').strip.squeeze(" ")
        json_array << {:value => name , :link => product_path(product), :name => product.filtered_name}
      end
      unless product.tags.blank?
        tags = product.tags.split(',')
        count = 0
        while count < tags.count
          unless  tags[count] =~ regex
            tag_name = Product.delete_trm(tags[count])
            json_array << {:value => tag_name, :link => product_path(product), :name => product.filtered_name}
          else
            tag_name = Product.delete_trm(tags[count])
            json_array << {:value => tag_name, :link => product_path(product), :name => product.filtered_name}
            name = tags[count].gsub(/([\/@()-])/, '').strip.squeeze(" ")
            tag_name = Product.delete_trm(name)
            json_array << {:value => tag_name , :link => product_path(product), :name => product.filtered_name}
          end
          count = count + 1
        end
      end
    end
    render :json => json_array.to_json
  end

  def index
    session[:return_to] = nil if params[:ref_logo] == 'home'
    @groups = Group.roots
    user = current_user.class.name
    @products = Product.recent_updates(user)
    store_location
    @actual_document_links=[]
  end

  def show
    product = Product.find(params[:id])
    if !current_user_is_admin?
      unless product.is_parent_product?
        unless product.published? || user_tib_employee?
          return redirect_if_not_tib_employee
        end
      else
        unless product.check_published || user_tib_employee?
          return redirect_if_not_tib_employee
        end
      end
    end
    return redirect_to product_path(product), status: :moved_permanently if request.path != product_path(product)
    def send_response(object)
      @product = object[:product]
      @groups = Group.roots
      @documents = object[:documents] unless object[:versions].blank?
      @versions = object[:versions] unless object[:versions].blank?
      store_location if object[:store_location]
      @actual_document_links=[]
    end
    if logged_in? && current_user_is_admin?
      send_response({:product => product,:versions => get_sorted_versions_for(product.id,:children), :store_location => true}) if product.is_parent_product?
      product.is_child_product? ? send_response({:product => product,:versions =>get_sorted_versions_for(product.id,:siblings),:documents => product.documents, :store_location => true}) : send_response({:product => product,:documents => product.documents, :store_location => true})
    else
      return redirect_to(products_path)  if !product.is_employee_level?
      store_product_path if !product.is_public_level? & !logged_in?
      if !product.is_public_level? & !logged_in?
        flash[:Need_Login?] = app_config(:product_require_login_message)
        return redirect_to(new_ldap_login_path)
      end
      if product.is_parent_product?
        array = get_sorted_versions_for(product.id,:children)
        if array.empty?
          return  redirect_to root_path
        else
          return redirect_to get_sorted_versions_for(product.id,:children).first[:url]
        end
      end
      send_response({:product => product,:versions =>get_sorted_versions_for(product.id,:siblings),:documents => product.documents, :store_location => true}) if product.is_child_product?
      send_response({:product => product,:documents => product.documents, :store_location => true}) if product.is_unversioned_product?
    end
  end


  def get_sorted_versions_for(product_id,relation)
    product = Product.find(product_id)
    children = product.send(relation)
    admin = current_user_is_admin?
    product_array = children.collect do |child|
      if admin
        {:id => child.id, :version => child.version_no, :url => product_path(child), :name => child.name }
      else
        if product.hold_until_ga && product.id == child.id && user_tib_employee?
          # add child to versions tab
          # if current_product is Hold until GA (not published)and
          #    child is current_product and
          #    current_user is TIBCO employee
          {:id => child.id, :version => child.version_no, :url => product_path(child), :name => child.name }
        elsif child.published?
          # if child is published
          {:id => child.id, :version => child.version_no, :url => product_path(child), :name => child.name }
        end
      end

    end
    product_array.delete_if{|product| product == nil}
    product_array.map do |product|
      product.each do |key,value|
        if key == :version
          temp_array = value.split('.')
          temp_array.each_with_index do |val,index|
            temp_array[index] = val.to_i
          end
          value= temp_array
        end
        product[key] = value
      end
    end
    product_array.sort!{|product_x,product_y| product_y[:version] <=> product_x[:version] }
    return product_array
  end

  def preview
    sorted_versions =  get_sorted_versions_for(@product.id,:children)
    @versions = sorted_versions
    @product = Product.find(sorted_versions.first[:id])
    @groups = Group.roots
    flash[:is_root] = true
  end

  def new
    @product = Product.new(params[:product])
    @new_request = true
  end

  def new_parent
    @product = Product.new(params[:product])
    @unverisoned_products = Product.roots.select{|product| !product.versioned? }
  end

  def edit
    return redirect_to edit_parent_product_path(@product) if @product.is_parent_product?
  end

  def edit_parent
    @unverisoned_products = Product.roots.select{|product| !product.versioned? }
    @verisoned_products = @product.children unless @product.children.blank?
    @versions = @product.children.sort_by!{|s| s.order}
  end

  def update
    save_update_product = lambda do |product,param|
      find_name = product.parent.blank? ? product.slug.underscore : product.version_no.parameterize.underscore
      if product.update_attributes(param)
        #update subject on tibco-docs.tibbr.com instance

        #begin
        #  if product.instance_variable_get('@previously_changed').include?('name')
        #    subject = TibbrIntegration.update_product_subject_by_name(find_name, product)
        #    product.update_attributes(:subject_name => subject['name']) unless subject['name'].blank?
        #  end
        #rescue
        #  redirect_to(root_path, :notice => 'Error in creating subject on tibbr.')
        #end

        redirect_to(product_path(product), :notice => 'Product was successfully updated.')
      else
        @product = product
        render :action => "edit"
      end
    end
    #if params[:product][:tags].blank?
    #  params[:product][:tags]= ""
    #else
    #  params[:product][:tags] = params[:product][:tags].join(',')
    #end
    begin
      ActiveRecord::Base.transaction do |block|
        save_update_product.call(@product,params[:product])
      end
    rescue => e
      ActiveRecord::Base.transaction do |block|
        if e.class == ActiveRecord::RecordNotUnique
          ActiveRecord::Base.connection.execute("Delete from friendly_id_slugs where slug='#{@product.slug}';")
          @product = Product.find(@product.id)
          save_update_product.call(@product,params[:product])
        end
      end
    end
  end

  def update_parent
    def save_updated_parent(product,versions, param)
      prev_prod_name = product.name
      find_name = product.slug.parameterize
      if product.update_attributes(param)
        product.free_versions unless versions.blank?
        product.add_version(versions) unless versions.blank?
        #update subject on tibco-docs.tibbr.com instance

        #begin
        #  subject = TibbrIntegration.update_product_subject_by_name(find_name, product)
        #  unless subject['name'].blank?
        #    product.update_attributes(:subject_name => subject['name'])
        #  end
        #rescue
        #  redirect_to(root_path, :notice => 'Error in creating subject on tibbr.')
        #end
        redirect_to(product_path(product), :notice => 'Product was successfully created.')
      else
        @product = product
        @versions = versions || []
        @unverisoned_products = Product.roots.select{|product| !product.versioned? }
        render :action => "new_parent"
      end
    end
    @versions = params[:product].delete("version")
    @product = Product.find(params[:id])
    if @versions.blank?
      @product.valid?
      @product.errors.add(:base,'must have atleast one version')
      @unverisoned_products = Product.roots.select{|product| !product.versioned? }
      @verisoned_products = @product.children unless @product.children.blank?
      render :action => "new_parent"
    end
    begin
      ActiveRecord::Base.transaction do |block|
        save_updated_parent(@product,@versions,params[:product])
      end
    rescue => e
      ActiveRecord::Base.transaction do |block|
        if e.class == ActiveRecord::RecordNotUnique
          ActiveRecord::Base.connection.execute("Delete from friendly_id_slugs where slug='#{@product.slug}';")
          @product = Product.find(@product.id)
          save_updated_parent(@product,@versions,params[:product])
        end
      end
    end
  end



  def create
    def save_new_product(product)
      if product.save
        #create subject on tibco-docs.tibbr.com instance

        #begin
        #  subject = TibbrIntegration.create_product_subject(product)
        #  unless subject['name'].blank?
        #    product.update_attributes(:subject_name => subject['name'])
        #  end
        #rescue
        #  redirect_to(root_path, :notice => 'Error in creating subject on tibbr.')
        #end
        redirect_to(product_path(product), :notice => 'Product was successfully created.')
      else
        @product = product
        render :action => "new"
      end
    end
    #if params[:product][:tags].blank?
    #  params[:product][:tags]= ""
    #else
    #  #@product = params[:product]
    #  ##@versions = versions || []
    #  ##@unverisoned_products = @product.roots.select{|product| !product.versioned? }
    #  ##@verisoned_products = @product.children unless @product.children.blank?
    #  ##puts params[:product][:tags].inspect
    #  ##puts params[:product][:tags].class
    #  ##params[:product][:tags] = params[:product][:tags].join(',')
    #  #render :action => "new"
    #  end
    @product = Product.new(params[:product])
    begin
      ActiveRecord::Base.transaction do |block|
        save_new_product(@product)
      end
    rescue => e
      ActiveRecord::Base.transaction do |block|
        if e.class == ActiveRecord::RecordNotUnique
          ActiveRecord::Base.connection.execute("Delete from friendly_id_slugs where slug='#{@product.slug}';")
          @product = Product.new(params[:product])
          save_new_product(@product)
        end
      end
    end
  end



  def create_parent
    def save_parent_product(product,versions)
      if product.save
        product.add_version(versions) unless versions.blank?
        #create subject on tibco-docs.tibbr.com instance

        #begin
        #  subject = TibbrIntegration.create_product_subject(product)
        #  unless subject['name'].blank?
        #    product.update_attributes(:subject_name => subject['name'])
        #  end
        #rescue
        #  redirect_to(root_path, :notice => 'Error in creating subject on tibbr.')
        #end
        redirect_to(product_path(product), :notice => 'Product was successfully created.')
      else
        @product = product
        @versions = versions
        @unverisoned_products = Product.roots.select{|product| !product.versioned? }
        render :action => "new_parent"
      end
    end
    #if params[:product][:tags].blank?
    #  params[:product][:tags]= ""
    #else
    #  @product = product
    #  @versions = versions || []
    #  @unverisoned_products = Product.roots.select{|product| !product.versioned? }
    #  @verisoned_products = @product.children unless @product.children.blank?
    #  render :action => "new_parent"
    #  params[:product][:tags] = params[:product][:tags].join(',')
    #end
    @versions = params[:product].delete("version")
    @product = Product.new(params[:product])
    @product.versioned = true
    if @versions.blank?
      @product.valid?
      @product.errors.add(:base,'must have atleast one version')
      @unverisoned_products = Product.roots.select{|product| !product.versioned? }
      render :action => "new_parent"
    end
    begin
      ActiveRecord::Base.transaction do |block|
        save_parent_product(@product,@versions)
      end
    rescue => e
      ActiveRecord::Base.transaction do |block|
        if e.class == ActiveRecord::RecordNotUnique
          ActiveRecord::Base.connection.execute("Delete from friendly_id_slugs where slug='#{@product.slug}';")
          product = Product.new(params[:product])
          product.versioned = true
          save_parent_product(product,@versions)
        end
      end
    end
  end



  def destroy
    def delete_parent(product)
      product.free_versions
      product.destroy
      return redirect_to products_url
    end
    if @product.is_parent_product?
      delete_parent(@product)
    else
      @product.destroy
      return redirect_to products_url
    end
  end



  def search
    filters = params[:filters].split('|')
    url = "#{app_config(:gsa,:url)}/search?#{search_url(params[:query],filters)}"
    @search_result = xml_parsed_to_search_results(URI.escape(url))
    @search_url = URI.escape("search?#{search_url(params[:query])}")
  end

  def suggest
    token = params[:token]
    site = logged_in? ? app_config(:gsa,:collections,:emp) : app_config(:gsa,:collections,:pub)
    url = URI.escape("#{app_config(:gsa,:url)}/suggest?token=#{token}&site=#{site}&max_matches=10&client=my_frontend&use_similar=0")
    suggestions = RestClient.get(url)
    render :json => suggestions
  end

  def find
    unless params[:find][:product_name].blank?
      @product_name = params[:find][:product_name]
      name = params[:find][:product_name].gsub(/([\/@()-])/, '').strip.squeeze(" ")
      name = Product.delete_trm(name)
      name = params[:find][:product_name] if name.length <=1
      product_array = Product.quick_find_result(logged_in?,current_user_is_admin?)
      @products = []
      include_words = []
      count = 0
      while count <= product_array.count
        unless product_array[count].nil?
          if product_array[count][:value].to_s.downcase.index(name.strip.squeeze(" ").downcase)  and !include_words.include?product_array[count][:name].to_s.downcase
            include_words.push(product_array[count][:name].to_s.downcase)
            begin
              @products.push(Product.find(product_array[count][:link].split("/").last))
            rescue
              #ignore
            end
          end
        end
        count = count + 1
      end
      @products.sort!{|x,y| x[:slug] <=> y[:slug]}
      @groups = Group.roots
      redirect_to product_path(@products.first)    if @products.size == 1
    else
      @products = []
      @groups = Group.roots
      redirect_to product_path(@products.first)    if @products.size == 1
    end
  end

  def search_tab
    all_products = logged_in? ? Product.employee_products : Product.public_products

    @prod_list = all_products.select{|product| !product.is_parent_product? }.to_json(:only =>[:id ,:filtered_name])
    if params[:query]
      search
    end
  end

  def feedback
    render :layout => false
  end

  def audit_info
    @audits = Audit.where(:payload_type => 'Product')
    admins = Admin.all.to_json(:only => [:id,:username])
    @admin_key_map = ActiveSupport::JSON.decode(admins)
  end

  def a_z_products
    store_location
    if current_user.is_a?(Admin)
      @products = Product.roots.order('filtered_name')
    else
      all_products = Product.employee_products
      @products = all_products.select{|product| product.is_root?}
    end
    @groups = Group.roots
  end

  def get_csv_report
    response = Product.get_csv_reports_of_products(params)
    respond_to do |format|
      format.csv do
        require 'csv'
        require 'open-uri'
        send_data response[0],:type => "text/csv; charset=iso-8859-1; header=present",:disposition => "attachment; filename= #{response[1]}"
      end
    end
  end

  def get_latest_detail_release_report
    response = Product.get_latest_detail_report
    respond_to do |format|
      format.csv do
        require 'csv'
        require 'open-uri'
        send_data response[0],:type => "text/csv; charset=iso-8859-1; header=present",:disposition => "attachment; filename= #{response[1]}"
      end
    end
  end

  def get_breadcum_report
    response = Product.get_category_report
    respond_to do |format|
      format.csv do
        require 'csv'
        require 'open-uri'
        send_data response[0],:type => "text/csv; charset=iso-8859-1; header=present",:disposition => "attachment; filename= #{response[1]}"
      end
    end
  end

  def get_latest_brief_release_report
    response = Product.get_latest_brief_report
    respond_to do |format|
      format.csv do
        require 'csv'
        require 'open-uri'
        send_data response[0],:type => "text/csv; charset=iso-8859-1; header=present",:disposition => "attachment; filename= #{response[1]}"
      end
    end
  end

  def get_ooc_report
    response = Product.out_of_cycle_report
    respond_to do |format|
      format.csv do
        require 'csv'
        require 'open-uri'
        send_data response[0],:type => "text/csv; charset=iso-8859-1; header=present",:disposition => "attachment; filename= #{response[1]}"
      end
    end

  end

  def get_ga_report
    response = Product.get_ga_report
    respond_to do |format|
      format.csv do
        require 'csv'
        require 'open-uri'
        send_data response[0],:type => "text/csv; charset=iso-8859-1; header=present",:disposition => "attachment; filename= #{response[1]}"
      end
    end
  end

  def get_all_reports
    response = Product.create_all_reports_archive
    respond_to do |format|
      format.zip do
        if response.blank?
          redirect_back_or_default
        else
          send_file response,:filename => "all_reports_#{Time.now.strftime("%Y_%m_%d")}.zip", :type => 'application/zip', :disposition => "attachment", :status => :ok
        end
      end
    end
  end

  def doc_names
    product = Product.find(params[:product_id])
    doc_names = product.blank? ? [] : product.get_other_versions_doc_names
    render :json => doc_names
  end

  private
  def init_controller
    case action_name.to_sym
      when :show, :edit,:update, :destroy, :feedback, :edit_parent, :delete_parent, :preview
        begin
          @product = Product.find(params[:id])
        rescue
          redirect_to root_path
        end
    end
  end

  def search_url(query,filter=nil)
    append_query = []
    sub_directory = nil

    unless filter.blank?
      prod = Product.find_by_filtered_name(filter)
      if prod.public?
        sub_directory =  app_config(:path,:public)
        append_query << "site:#{app_config(:site_url)}/#{sub_directory}/#{prod.folder_path}"
      else
        sub_directory =  app_config(:path,:employee)
        append_query << "site:#{app_config(:site_url)}/#{sub_directory}/#{prod.folder_path}"
      end
    end

    #sub_directory = logged_in? ? app_config(:path,:employee) : app_config(:path,:public)
    #
    #filters.each do |filter|
    #  prod = Product.find_by_filtered_name(filter)
    #  append_query << "site:#{app_config(:site_url)}/#{sub_directory}/#{prod.folder_path}" unless prod.blank?
    #end
    site = logged_in? ? app_config(:gsa,:collections,:emp) : app_config(:gsa,:collections,:pub)
    if append_query.blank?
      #return "q=#{query} site:#{URI.parse(request.url).host}&site=#{site}&client=my_frontend&output=xml&sort=date:D:L:d1&filter=#{app_config(:search,:filter)}"
      return "q=#{query}&site=#{site}&client=my_frontend&output=xml&sort=date:D:L:d1&filter=#{app_config(:search,:filter)}"
    else
      #return "q=#{query} #{append_query.join(' OR ')}&site=#{site}&client=my_frontend&output=xml&sort=date:D:L:d1&filter=#{app_config(:search,:filter)}"
      return "q=#{query} #{append_query.join(' OR ')}&site=#{site}&client=my_frontend&output=xml&sort=date:D:L:d1&filter=#{app_config(:search,:filter)}"
    end

  end

  private
  def redirect_if_not_tib_employee
    store_product_path
    store_active_login_tab("employee-login") unless logged_in?
    return redirect_to new_ldap_login_path
  end
end