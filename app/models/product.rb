# encoding: UTF-8

class Product < ActiveRecord::Base
  require 'archive/zip'
  require 'fileutils'
  extend FriendlyId
  friendly_id :name, use: :history
  attr_accessor :access_level , :hold_until_ga
  has_ancestry :orphan_strategy => :rootify
  has_many  :group_products, :dependent => :destroy
  has_many  :groups, :through => :group_products
  has_many  :documents, :dependent => :destroy
  accepts_nested_attributes_for :groups
  ActiveRecord::Base.include_root_in_json = false

  validates_presence_of :name, :message => "can't be blank"
  validates_presence_of :folder_path, :message => "can't be blank", :if => Proc.new { |product| product.is_unversioned_product? || product.is_child_product?}

  validates_uniqueness_of :name, :case_sensitive => false

  validate :product_must_have_group
  validate :check_product_folder_path, :if => Proc.new { |product| product.is_unversioned_product? || product.is_child_product? }

  before_save :filter_tm_reg_and_copyright_chars_from_name,:remove_slash

  def remove_slash()
      until self.folder_path[0]!="/" do
         self.folder_path.slice!(0,1)
      end
  end  

  def hold_until_ga
    !self.published
  end

  def hold_until_ga=(val)
    self.published = !(val == '1')
    set_published_date if self.changes.keys.include?('published') && self.published?
  end

  def set_published_date
    self.published_date = DateTime.now
  end

  def get_recent_update_message
    "added on #{published_date.strftime('%F')}"
  end

  def name_filter
    name_string = name
    name_string.gsub("®".force_encoding('utf-8'),"<sup>®</sup>").gsub('&reg;',"<sup>®</sup>").gsub("&REG;","<sup>®</sup>").gsub('&reg',"&amp;reg").gsub('&REG',"&amp;REG").html_safe
  end

  def create_tibbr_subject
    return false unless self.valid?
    subject = TibbrIntegration.create_product_subject(self)
    return true unless subject.blank?
  end

  def filter_tm_reg_and_copyright_chars_from_name
    filtered_name = self.name.delete "™"
    filtered_name = filtered_name.delete "®"
    filtered_name = filtered_name.delete "©"
    self.filtered_name = filtered_name
  end

  def self.delete_trm(string)
    filtered_name = string.delete "™"
    filtered_name = filtered_name.delete "®"
    filtered_name = filtered_name.delete "©"
    return filtered_name
  end

  def access_level=(attr=nil)
    unless attr.blank? && product_access_level_collection.has_value?(attr)
      case product_access_level_collection.invert[attr]
        when "Site Admin Only"
          self.public=false
          self.visible=false
        when "Requires Login"
          self.public=false
          self.visible=true
        when "For General Public"
          self.public=true
          self.visible=true
      end
    end
  end

  def access_level
    if is_public_level?
      return product_access_level_collection["For General Public"]
    elsif is_employee_level?
      return product_access_level_collection["Requires Login"]
    elsif is_admin_level?
      return product_access_level_collection["Site Admin Only"]
    end
  end

  def visibility
    str =  self.is_public_level? ? "public" : self.is_employee_level? ? "login" : "admin"
    return str
  end

  def product_must_have_group
    self.errors.add(:groups,"Product must belong to at least one category.") if self.groups.blank?
  end

  def doc_types_for_product
    arr = []
    self.documents.each { |doc| arr << doc.doc_type.doctype }
    return arr.uniq
  end

  def self.public_products(product_name = "",condition=[])
    return self.order('filtered_name').all(:conditions => {:public => true, :visible => true, :name => product_name , :published => true}) unless product_name.blank?
    unless condition.blank?
      cond = "public=:public and visible=:visible and " + condition[0]
      cond_hash = {:public => true, :visible => true , :published => true}.merge(condition[1])
      return self.order('filtered_name').all(:conditions => [cond, cond_hash])
    end

    return self.order('filtered_name').all(:conditions => {:public => true, :visible => true , :published => true})
  end

  def self.employee_products(product_name = "",condition=[])
    return self.order('filtered_name').all(:conditions => {:visible => true, :name => product_name,:published => true}) unless product_name.blank?
    unless condition.blank?
      cond = "visible=:visible and " + condition[0]
      cond_hash = {:visible => true , :published => true}.merge(condition[1])
      return self.order('filtered_name').all(:conditions => [cond,cond_hash])
    end
    return self.order('filtered_name').all(:conditions => {:visible => true,:published => true})
  end

  def self.tib_employee_products(product_name = "",condition=[])
    return self.order('filtered_name').all(:conditions => {:visible => true, :name => product_name }) unless product_name.blank?
    unless condition.blank?
      cond = "visible=:visible and " + condition[0]
      cond_hash = {:visible => true }.merge(condition[1])
      return self.order('filtered_name').all(:conditions => [cond,cond_hash])
    end
    return self.order('filtered_name').all(:conditions => {:visible => true })
  end

  def self.filtered_employee_products(product_name = "",condition=[])
    return self.order('filtered_name').all(:conditions => {:visible => true, :name => product_name}) unless product_name.blank?
    unless condition.blank?
      cond = "visible=:visible and " + condition[0]
      cond_hash = {:visible => true}.merge(condition[1])
      return self.order('filtered_name').all(:conditions => [cond,cond_hash])
    end
    return self.order('filtered_name').all(:conditions => {:visible => true})
  end

  def self.admin_products(product_name = "",condition=[])
    return self.order('filtered_name').all(:conditions => {:name => product_name }) unless product_name.blank?
    return self.order('filtered_name').all(:conditions => condition ) unless condition.blank?
    return self.order('filtered_name').all(:conditions => {:visible => true })
  end

  def is_public_level?
    return true if self.public? && self.visible?
  end

  def is_employee_level?
    return true if self.visible?
  end

  def is_employee_product?
    return true if self.visible? && self.public? == false
  end

  def is_admin_level?
    return true
  end

  def is_only_for_admin?
    return true if !self.visible? && !self.public?
  end

  def product_access_level_collection
    return {"Site Admin Only" => "1", "Requires Login" => "2", "For General Public" => "3"}
  end

  def check_published
    if self.is_parent_product?
      visible = false
      childrens = self.children
      childrens.each do |child|
        if child.published
          visible = true
        end
      end
      return visible
    else
      return true
    end
  end

  def parent_groups(group_id)
    if group_id.blank?
      group_id = self.groups.first.id
    else
      arr = group_id.split("?")
      group_id = arr[0] unless arr.blank?
    end
    group = Group.find(group_id)
    all_parents = Group.ancestors_of(group)
    arr = []
    all_parents.each{|p| arr << p.name}
    arr << group.name
    arr.join(" > ")
  end

  def create_archive(documents_link_array)           ## takes documents_link_array as argument containing Product doc's links to be archived
    unless documents_link_array.empty?
      zip_file_link = "#{app_config[:ftp_root]}/#{self.folder_path}/#{self.slug}_documentation.zip"
      delete_stat = File.delete(zip_file_link) if  File.exists?(zip_file_link)
      archive_stat = Archive::Zip.archive(zip_file_link, documents_link_array )

      if archive_stat == nil
        # to change the file permissions/ownership and modes
        #  username = ("#{app_config[:ftp_username]}")
        # groupname = ("#{app_config[:ftp_groupname]}")
        #  FileUtils.chown username, groupname, zip_file_link
        ftp_chmod = (0775)
        File.chmod(ftp_chmod, zip_file_link)
        puts File.stat(zip_file_link).inspect
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def delete_archive
    delete_stat = File.delete("#{app_config[:ftp_root]}/#{self.folder_path}/#{self.slug}_documentation.zip") if  File.exists?("#{app_config[:ftp_root]}/#{self.folder_path}/#{self.slug}_documentation.zip")
    if delete_stat == 1
      return true
    else
      return false
    end
  end

  def check_product_folder_path
    self.errors.add(:folder_path ,"folder path doesn't exist on FTP") unless  File.directory?("#{app_config[:ftp_root]}/#{self.folder_path}")
  end

  def self.recent_updates(user, user_tib_employee= nil )
    if user == "Admin"
      all_products = Product.all(:order => "published_date DESC",:conditions =>{:published_date => (DateTime.now - 2.weeks)..DateTime.now })
    else
      conditions = {:visible=> true, :published_date => (DateTime.now - 2.weeks)..DateTime.now}
      conditions.merge!(:published => true) unless user_tib_employee
      all_products = Product.all(:order => "published_date DESC", :conditions => conditions )
    end
    return all_products.select{|product| !product.is_parent_product? }
  end

  def recent_updated_document
    self.documents.order("created_at").select{|d| DateTime.now.to_date - 2.weeks.since(d.created_at).to_date <=0 }
  end

  def time_diff_in_ms(datetime2,datetime1)
    time1 = datetime1.split(":")
    hr1 = time1[0].to_i
    min1 = time1[1].to_i
    sec1 = time1[2].to_i
    ms1 = time1[3].to_i

    time2 = datetime2.split(":")
    hr2 = time2[0].to_i
    min2 = time2[1].to_i
    sec2 = time2[2].to_i
    ms2 = time2[3].to_i

    return ((hr2-hr1)*60*60*1000 + (min2-min1)*60*1000 + (sec2-sec1)*1000 + (ms2-ms1))
  end

  def free_versions
    children  = self.children
    unless children.blank?
      children.each do |child|
        child.update_attributes_without_timestamping({:ancestry => nil, :versioned => false , :default => nil})
      end
    end
  end

  def add_version(versions)
    versions.each_with_index do |version, index|
      ver_product = Product.find(version[:id])
      version_no = version[:version_no] unless  version[:version_no].strip == ""
      ver_product.update_attributes_without_timestamping({:ancestry => self.id, :version_no => version_no,:oem => self.oem, :visible => self.visible, :public => self.public, :versioned => true, :order => index, :group_ids => self.group_ids})
    end
  end

  def is_parent_product?
    self.is_root? && self.versioned?
  end

  def is_child_product?
    !self.is_root? && self.versioned?
  end

  def is_unversioned_product?
    self.is_root? && !self.versioned?
  end

  def self.find_first_children(product_id,relation)
    begin
      children = Product.find(product_id).send(relation)
      product_array = children.collect{|child| { :child => child ,  :id => child.id, :version => child.version_no, :name => child.name }}
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
      return product_array[0][:child]
    rescue
      return nil
    end

  end


  def self.get_csv_reports_of_products(params=nil)
    require 'csv'
    require 'open-uri'
    if  params[:id] == "detailed"
      emp_count = pub_count = admin_count = doc_count = total_pdf_page = total_OEM_products =  0
      all_products= Product.all(:order => 'filtered_name')
      @products = all_products.select{|product| !product.is_parent_product? }
      csv_string=""
      csv_string += ["Product Name","Documents","Require Login","For General Public","Site admin only","Number of Docs","OEM","Number of pages","Out of Cycle Update"].to_csv
      @products.each do |product|
        if product.is_employee_product?
          is_employee = "TRUE"
          emp_count = emp_count + 1
        end
        if product.is_public_level?
          is_public = "TRUE"
          pub_count = pub_count + 1
        end
        if product.is_only_for_admin?
          is_admin =  "TRUE"
          admin_count = admin_count + 1
        end
        if product.oem == true
          isOEM =  'TRUE'
          total_OEM_products = total_OEM_products + 1
        end
        documents = product.documents
        unless documents.blank?
          documents.each do |document|
            csv_string += [product.filtered_name.strip, document.name.strip, is_employee , is_public ,is_admin, documents.size ,isOEM, document.pdf_count,document.out_of_cycle_update_csv].to_csv
            total_pdf_page = total_pdf_page + document.pdf_count  unless document.pdf_count == nil
            doc_count = doc_count + 1
          end
        else
          csv_string += [product.filtered_name.strip, "", is_employee , is_public ,is_admin, 0 ,isOEM].to_csv
        end
        csv_string += [""].to_csv
      end
      csv_string += [""].to_csv
      csv_string += ["Total Count","",emp_count,pub_count,admin_count,doc_count,total_OEM_products,total_pdf_page].to_csv
      filename = "docsite_detail_report_#{Time.now.strftime("%Y_%m_%d")}"
      #  send_data csv_string,:type => "text/csv; charset=iso-8859-1; header=present",:disposition => "attachment; filename=#{filename}.csv"
      return [csv_string,"#{filename}.csv"]
    end
    if  params[:id] == "brief"
      emp_count = pub_count = admin_count = doc_count = total_OEM_products = all_pdf_pages =  0
      all_products= Product.all(:order => 'filtered_name')
      @products = all_products.select{|product| !product.is_parent_product? }
      csv_string=""
      csv_string += ["Product Name","Visibility","Number of Docs","OEM","Number of pages in PDF"].to_csv
      csv_string +=[""].to_csv
      @products.each do |product|
        visibility = product.visibility
        emp_count = emp_count + 1   if product.is_employee_product?
        pub_count = pub_count + 1   if product.is_public_level?
        admin_count = admin_count + 1 if product.is_only_for_admin?
        if product.oem == true
          isOEM =  'TRUE'
          total_OEM_products = total_OEM_products + 1
        end
        documents = product.documents
        doc_count = documents.size
        total_pdf_pages = 0
        unless documents.blank?
          documents.each do |document|
            total_pdf_pages = total_pdf_pages + document.pdf_count  unless document.pdf_count == nil
          end
        else
          total_pdf_page = 0
        end
        all_pdf_pages = all_pdf_pages + total_pdf_pages
        csv_string += [product.filtered_name.strip,visibility,doc_count,isOEM,total_pdf_pages].to_csv
      end
      csv_string += ["Total Count","",Document.all.size,total_OEM_products,all_pdf_pages].to_csv
      csv_string += [""].to_csv
      csv_string += ["Total products for General Public",pub_count ].to_csv
      csv_string += ["Total products Requires Login",emp_count ].to_csv
      csv_string += ["Total products Site Admin Only",admin_count ].to_csv
      csv_string += ['Total products on site',"#{@products.size}"].to_csv
      filename = "docsite_brief_report_#{Time.now.strftime("%Y_%m_%d")}"
      return [csv_string,"#{filename}.csv"]
    end
  end

  def self.get_latest_detail_report
    require 'csv'
    require 'open-uri'
    emp_count = pub_count = admin_count = doc_count = total_pdf_page = total_OEM_products =  0
    all_products= Product.all(:order => 'filtered_name')
    @products = all_products.select{|product| product.is_parent_product? }
    csv_string=""
    csv_string += ["Product Name","Documents","Require Login","For General Public","Site admin only","Number of Docs","OEM","Number of pages","Out of Cycle Update"].to_csv
    @products.each do |prod|
      product = Product.find_first_children(prod.id,:children)
      unless product.blank?
        if product.is_employee_product?
          is_employee = "TRUE"
          emp_count = emp_count + 1
        end
        if product.is_public_level?
          is_public = "TRUE"
          pub_count = pub_count + 1
        end
        if product.is_only_for_admin?
          is_admin =  "TRUE"
          admin_count = admin_count + 1
        end
        if product.oem == true
          isOEM =  'TRUE'
          total_OEM_products = total_OEM_products + 1
        end
        documents = product.documents
        count = documents.select("name").where(:name => "license agreement").count
        unless documents.blank?
          documents.each do |document|
            unless (document.name.downcase).include? "license agreement"
              csv_string += [product.filtered_name.strip, document.name.strip, is_employee , is_public ,is_admin, documents.size - count,isOEM, document.pdf_count,document.out_of_cycle_update_csv].to_csv
              total_pdf_page = total_pdf_page + document.pdf_count  unless document.pdf_count == nil
              doc_count = doc_count + 1
            end
          end
        else
          csv_string += [product.filtered_name.strip, "", is_employee , is_public ,is_admin, 0 ,isOEM].to_csv
        end
        csv_string += [""].to_csv
      end
    end
    csv_string += [""].to_csv
    csv_string += ["Total Count","",emp_count,pub_count,admin_count,doc_count,total_OEM_products,total_pdf_page].to_csv
    filename = "docsite_latest_releases_detail_report_#{Time.now.strftime("%Y_%m_%d")}"
    #  send_data csv_string,:type => "text/csv; charset=iso-8859-1; header=present",:disposition => "attachment; filename=#{filename}.csv"
    return [csv_string,"#{filename}.csv"]
  end

  def self.get_latest_brief_report
    require 'csv'
    require 'open-uri'
    emp_count = pub_count = admin_count = doc_count = total_OEM_products = all_pdf_pages = total_doc_size =  0
    all_products= Product.all(:order => 'filtered_name')
    @products = all_products.select{|product| product.is_parent_product? }
    csv_string=""
    csv_string += ["Product Name","Visibility","Number of Docs","OEM","Number of pages in PDF"].to_csv
    csv_string +=[""].to_csv
    @products.each do |prod|
      product = Product.find_first_children(prod.id,:children)
      unless product.blank?
        visibility = product.visibility
        emp_count = emp_count + 1   if product.is_employee_product?
        pub_count = pub_count + 1   if product.is_public_level?
        admin_count = admin_count + 1 if product.is_only_for_admin?
        if product.oem == true
          isOEM =  'TRUE'
          total_OEM_products = total_OEM_products + 1
        end
        documents = product.documents
        doc_count = documents.size - product.documents.select("name").where(:name => "license agreement").count
        total_doc_size = doc_count + total_doc_size
        total_pdf_pages = 0
        unless documents.blank?
          documents.each do |document|
            unless (document.name.downcase).include? "license agreement"
              total_pdf_pages = total_pdf_pages + document.pdf_count  unless document.pdf_count == nil
            end
          end
        else
          total_pdf_page = 0
        end
        all_pdf_pages = all_pdf_pages + total_pdf_pages
        csv_string += [product.filtered_name.strip,visibility,doc_count,isOEM,total_pdf_pages].to_csv
      end
    end
    csv_string += ["Total Count","",total_doc_size,total_OEM_products,all_pdf_pages].to_csv
    csv_string += [""].to_csv
    csv_string += ["Total products for General Public",pub_count ].to_csv
    csv_string += ["Total products Requires Login",emp_count ].to_csv
    csv_string += ["Total products Site Admin Only",admin_count ].to_csv
    csv_string += ['Total products on site',"#{@products.size}"].to_csv
    filename = "docsite_latest_releases_brief_report_#{Time.now.strftime("%Y_%m_%d")}"
    return [csv_string,"#{filename}.csv"]
  end


  def self.get_category_report
    require 'csv'
    require 'open-uri'
    csv_string =""
    root_categories  = Group.roots
    root_categories.each do |categorie|
      root_category_products = categorie.products.select {|product| !product.is_child_product?}
      root_category_products.sort! { |a,b| a.filtered_name.downcase.strip <=> b.filtered_name.downcase.strip }
      unless root_category_products.blank?
        root_category_products.each do |product|
          csv_string += [Product.delete_trm(categorie.name.strip) , product.filtered_name.strip].to_csv
        end
      end
      all_sub_category = categorie.descendants
      all_sub_category.sort! { |a,b| Product.delete_trm(a.name.downcase.strip) <=> Product.delete_trm(b.name.downcase.strip) }
      all_sub_category.each do |sub_cat|
        categorie_products = sub_cat.products.select {|product| !product.is_child_product?}
        categorie_products.sort! { |a,b| a.slug.downcase.strip <=> b.slug.downcase.strip }
        parent_categories = sub_cat.ancestors.collect {|cat| Product.delete_trm(cat.name.strip)}
        unless categorie_products.blank?
          categorie_products.each do |product|
            csv_string += sub_cat.ancestors.collect {|cat| Product.delete_trm(cat.name.strip)}.concat([Product.delete_trm(sub_cat.name.strip),product.filtered_name.strip]).to_csv
          end
        else
          csv_string += sub_cat.ancestors.collect {|cat| Product.delete_trm(cat.name.strip)}.concat([Product.delete_trm(sub_cat.name.strip) , "No Products for this category"]).to_csv
        end
      end
    end
    return [csv_string,"product_breadcrumb_report.csv"]
  end


  def self.out_of_cycle_report
    require 'csv'
    require 'open-uri'
    out_of_cycle_audit = Audit.where("modified_attributes like ?", "%out_of_cycle%").sort {|x,y| x.updated_at <=> y.updated_at}.reverse
    csv_string=""
    csv_string += ["Product Name","Document Name" ,"User Name","Out-Of-Cycle-Date"].to_csv
    out_of_cycle_audit.each do |audit|
      begin
        document =  Document.find(audit.payload_id)
        user_detail = User.find(audit.user_id)
        csv_string += [document.product.filtered_name.strip.squeeze(" "),document.name.strip.squeeze(" "),user_detail.firstname + " " + user_detail.lastname,audit.updated_at].to_csv
      rescue
        #ignore
      end
    end
    return [csv_string,"out_of_update_cycle_report.csv"]
  end

  def self.get_non_parent_products
    products = Product.where(:published => false ).order(:filtered_name)
  end

  def self.get_ga_report
    products = get_non_parent_products
    products.reject{|product| product.is_parent_product?}
    ga_report(products)
  end

  def self.ga_report(products)
    require 'csv'
    require 'open-uri'
    csv_string=""
    csv_string += ["Product Name"].to_csv
    products.each do |product|
      csv_string +=[product.filtered_name].to_csv
    end

    return [csv_string,"hold_untill_ga_report.csv"]
  end


  def self.quick_find_result(check_login,current_user_admin, user_tib_employee = nil)
    all_products = Product.all
    products =  check_login && current_user_admin ? all_products.select{|product| !product.is_child_product?} : all_products.select{|product| !product.is_child_product? && product.visible? && product.published? && product.check_published}
    json_array = []
    special = "-()/@"
    regex = /[#{special.gsub(/./){|char| "\\#{char}"}}]/
    products.each do |product|
      filter_name = product.filtered_name
      unless  product.filtered_name =~ regex
        json_array << {:value => product.filtered_name.squeeze(" ").strip, :link => product_path(product), :name => product.filtered_name.squeeze(" ").strip}
      else
        json_array << {:value => product.filtered_name.squeeze(" ").strip, :link => product_path(product), :name => product.filtered_name.squeeze(" ").strip}
        name = filter_name.gsub(/([\/@()-])/, '').strip.squeeze(" ")
        json_array << {:value => name.squeeze(" ").strip , :link => product_path(product), :name => product.filtered_name.squeeze(" ").strip}
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
    return json_array
  end


  def get_other_versions_doc_names
    is_child_product? ?  parent.children.map{|ver| ver.documents.map(&:name)}.flatten.uniq : []
  end

  def self.get_all_reports
    detailed_report    = get_csv_reports_of_products({:id => "detailed"})
    brief_report       = get_csv_reports_of_products({:id => "brief"})
    latest_detail_report  = get_latest_detail_report
    latest_brief_report   = get_latest_brief_report
    category_report    = get_category_report
    ooc_report         = out_of_cycle_report
    ga_report          = get_ga_report

    detailed_report[1] = "docsite_detail_report_#{Time.now.strftime("%Y_%m_%d")}.csv"
    brief_report[1]    = "docsite_brief_report_#{Time.now.strftime("%Y_%m_%d")}.csv"
    latest_detail_report[1]  = "docsite_latest_releases_detail_report_#{Time.now.strftime("%Y_%m_%d")}.csv"
    latest_brief_report[1]   = "docsite_latest_releases_brief_report_#{Time.now.strftime("%Y_%m_%d")}.csv"
    category_report[1] = "product_category_report_#{Time.now.strftime("%Y_%m_%d")}.csv"
    ooc_report[1]      = "out_of_cycle_report_#{Time.now.strftime("%Y_%m_%d")}.csv"
    ga_report[1]      = "hold_untill_ga_report_#{Time.now.strftime("%Y_%m_%d")}.csv"

    #return [ ooc_report]
    return [detailed_report, brief_report, latest_detail_report, latest_brief_report, category_report, ooc_report, ga_report]
  end

  def self.create_all_reports_archive
    timestamp = Time.now.strftime("%Y_%m_%d")
    basepath = "#{Rails.root}#{app_config(:reports_path)}"
    archive_file_path = "#{basepath}/all_reports.zip"

    #create a temporary directory to hold all csv report files
    tmp_dir  = FileUtils.mkdir_p("#{basepath}/all_reports_#{timestamp}/")
    unless tmp_dir.empty?
      FileUtils.chmod 0766, tmp_dir.first

      #Iterate through each report files retrieved from method 'get_all_reports'
      get_all_reports.each do |report|
        file_path = "#{tmp_dir.first}#{report[1].to_s}"
        #create a csv file for each report
        File.open(file_path, "w+", 766) {|f|  f.puts  report[0] }
        FileUtils.chmod 0766, file_path
        logger.info "File Created => #{file_path}"
      end

      #create archive file of all csv report files
      archive_file_path = archive_reports(archive_file_path, tmp_dir.first.to_s)

      is_deleted_tmp_dir = FileUtils.remove_dir(tmp_dir.first) === 0
      logger.info is_deleted_tmp_dir ? "Temporary Directory(#{tmp_dir.first.to_s}) removed successfully" : "Temporary Directory(#{tmp_dir.first.to_s}) not removed successfully"
    end
    archive_file_path
  end

  def self.archive_reports(archive_file_path, report_files_dir_path)
    begin
      File.delete(archive_file_path) if  File.exists?(archive_file_path)
      logger.info  "#{'-'*50} \n report_files_dir_path : #{report_files_dir_path} \n archive_file_path : #{archive_file_path} \n#{'-'*50}"
      Archive::Zip.archive(archive_file_path, report_files_dir_path )
      FileUtils.chmod 0766, archive_file_path
      return  archive_file_path
    rescue => e
      Rails.logger.info "ERROR in creating archive[#{archive_file_path}]"
      Rails.logger.info e.message
      return nil
    end
  end

end