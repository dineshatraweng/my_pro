class Document < ActiveRecord::Base

  require 'uri'
  require 'pdf/reader'

  belongs_to :product
  belongs_to :doc_type

  after_save :update_project_timestamp
  after_destroy :update_project_timestamp
  before_save :remove_slash

  validates_presence_of :name
  validates_presence_of :link
  validates :description, length:{ maximum: 200, message: "Description can't be more than 200 characters." }, allow_blank: true

  validate :check_document_path

  DOCTYPE={:folder_path => 'FOLDER_PATH',:windows => 'WINDOWS' }

 
  def remove_slash()
      until self.link[0]!="/" do
         self.link.slice!(0,1)
      end
  end  

  def build_link_to_doc(host,product_path)
    return "#{host}#{product_path}#{self.link}"
  end

  def update_project_timestamp
    self.product.update_attributes(:updated_at => DateTime.now)
  end

  def document_order_value(product)
    if product.documents.blank?
      return 1
    else
      if product.documents.order('document_order').last.blank?
        return 1
      else
        return (product.documents.order('document_order').last.document_order + 1)
      end
    end
  end

  def rearrange_document_order_before_save
    document = Document.first(:conditions => {:product_id => self.product_id, :document_order => self.document_order})
    unless document.blank?
      dorder = document.document_order
      document.update_attributes(:document_order => (dorder + 1))
    end
  end

  def rearrange_document_order_before_destroy
    document = Document.first(:conditions => {:product_id => self.product_id, :document_order => self.document_order+1})
    unless document.blank?
      dorder = document.document_order
      document.update_attributes(:document_order => (dorder - 1))
    end
  end

  class PageReceiver
    attr_accessor :pages
    def page_count(arg)
      @pages = arg
    end
  end

  def is_a_pdf?
    if ( /.pdf$/.match(self.link))
      return true
    else
      return false
    end
  end

  def is_a_index_html?
    return true if ["index.html","index.htm","Index.html","Index.htm"].include?(File.split(self.link).last)
    return false
  end

  def get_index_html_files
    doc_link = File.split(self.link).first
    unless doc_link == "."
      return doc_link
    else
      return nil
    end
  end

  def update_count
    if self.is_a_pdf?
      result = self.do_pdf_count
      case result
        when 0
          return true       #PDF page count updated successfully
        when 2
          self.errors.add(:pdf_count, "The path does not exist on the server" )
          return false
        when 3
          self.errors.add(:pdf_count, "Bad File (unreadable)" )
          return false
        else
          return false
      end
    else
      return false         # when file is not a pdf.
    end
  end

  def do_pdf_count(option = false)
    option ||= DateTime.now
    receiver = PageReceiver.new
    doc_path = get_doc_full_ftp_path
    begin
      reader = PDF::Reader.file(doc_path, receiver, :pages => false)
      document_page_count = receiver.pages
      self.update_attributes(:pdf_count => document_page_count,:updated_at => option )
    rescue => e
      if e.to_s == "PDF::Reader cannot read encrypted PDF files"
        ob = PDF::Reader::ObjectHash.new(doc_path)
        return 5 if ob.trailer[:Encrypt]   #  5 when error occurs while reading a encrypted file
      else
        logger.info "======== #{doc_path} ========="
        logger.info e.message
        logger.info e.backtrace
        return 3   #  3 when error occurs while reading a file
      end
    end
    return 0     # 0 when pdf count is updates successfully
  end

  def check_document(product,task_start_time = false)
    doc_path = get_doc_full_ftp_path
    if File.file?(doc_path)   #check the file (document link) exists on FTP
      if self.updated_within_24hrs?    # Checks the document file is updated within 24 hrs
        if self.is_a_pdf?              # when file is a pdf
          self.do_pdf_count(task_start_time)            # pdf count is calculated
        else
          return 1          # 1 when file is not a pdf
        end
      else
        return 4            # 4 when  not updated within 24 hours
      end
    else
      return 2              # 2 when path does not exist on the FTP.
    end
  end

  def access_url(product)
    url = product.is_public_level? ? "#{app_config(:docs,:url)}/#{app_config(:path,:public)}" : "#{app_config(:docs,:url)}/#{app_config(:path,:employee)}"
    if is_doctype_folder_path?
      return url + "/#{product.folder_path}/#{self.link}"
    else
      return url + "/#{app_config(:docs,:proxy_path)}/#{self.link}"
    end

  end

  def check_product_updated(product)
    gr_time = eval(app_config[:update_check_time])
    return true if product.updated_at >= (DateTime.now - gr_time) and product.updated_at <= DateTime.now
    return false
  end

  def check_document_path
      #self.remove_starting_slash
    if is_doctype_windows?
      return document_exists_on_win_ftp
    elsif File.file?("#{app_config[:ftp_root]}/#{self.product.folder_path}/#{self.link}")
      return true
    else
      self.errors.add(:link ,"Document doesn't exist on FTP")
      return false
    end
  end

  def document_exists_on_win_ftp
    return true if File.file?("#{app_config[:win_ftp_root]}/#{self.link}")
    self.errors.add(:link ,"Document doesn't exist on Windows server FTP")
    return false
  end

  def updated_within_24hrs?
    doc_path = get_doc_full_ftp_path
    stat = File.stat(doc_path)
    gr_time = eval(app_config[:update_check_time])
    return true if (stat.ctime >= (DateTime.now - gr_time) and stat.ctime <= DateTime.now)
    return true if (stat.mtime >= (DateTime.now - gr_time) and stat.mtime <= DateTime.now)
    return true if self.updated_at >= (DateTime.now - gr_time) and self.updated_at <= DateTime.now
    return false
  end

  def set_out_of_cycle
    self.out_of_cycle == DateTime.now
    self.save
  end

  def out_of_cycle_update_csv
    self.out_of_cycle.strftime('%b %d %Y') unless self.out_of_cycle.nil?
  end

  def doc_modified_time
    if self.is_a_index_html?
      doc_path = is_doctype_folder_path? ? "#{app_config[:ftp_root]}/#{self.product.folder_path}/#{self.get_index_html_files}" : "#{app_config[:ftp_root]}/#{self.get_index_html_files}"
      stat = File.stat(doc_path)
    else
      doc_path = get_doc_full_ftp_path
      stat = File.stat(doc_path)
    end
    file_mod_time = stat.ctime > stat.mtime ? stat.ctime : stat.mtime
    return file_mod_time > self.updated_at ? file_mod_time : self.updated_at
  end

  def is_doctype_windows?
    self.doctype == DOCTYPE[:windows]
  end

  def is_doctype_folder_path?
    self.doctype == DOCTYPE[:folder_path]
  end

  def get_doc_full_ftp_path
    is_doctype_folder_path? ? "#{app_config[:ftp_root]}/#{self.product.folder_path}/#{self.link}" : "#{app_config[:win_ftp_root]}/#{self.link}"
  end
end


