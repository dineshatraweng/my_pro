class DocFtp < ActiveRecord::Base
  #attributes
  #@name  => Name of document to be unzipped
  #@path  => relative path
  #@doctype => Doctype based on location windows ftp or Folder path ()doc ftp root)
  #@status => unzipped status
  #@messages => error message describing cause to file not extracted

  require 'archive/zip'
  require 'fileutils'

  #DOCTYPE specifies where documents are located
  DOCTYPE = Document::DOCTYPE

  STATUS  = {:zipped => 'ZIPPED', :unzipped => 'UNZIPPED', :running => "RUNNING", :failed => 'FAILED'}

  validates :path, presence: true
  validate  :check_document_path

  scope :zipped_files,   where(:status => STATUS[:zipped])
  scope :unzipped_files, where(:status => STATUS[:unzipped])
  scope :failed_files,   where(:status => STATUS[:failed])


  def check_document_path
    is_a_zip? && is_document_exists?
  end

  def is_doctype_windows?
    doctype == DOCTYPE[:windows]
  end

  def is_doctype_folder_path?
    doctype == DOCTYPE[:folder_path]
  end

  def get_doc_full_ftp_path
    is_doctype_folder_path? ? "#{app_config[:ftp_root]}/#{path}" : "#{app_config[:win_ftp_root]}/#{path}"
  end

  def is_document_exists?
    is_doctype_windows? ? document_exists_on_win_ftp : document_exists_on_ftp_root
  end

  def document_exists_on_win_ftp
    document_exists_on(:win_ftp_root, "Windows server FTP")
  end

  def document_exists_on_ftp_root
    document_exists_on(:ftp_root, "FTP")
  end

  def document_exists_on(location, location_name)
    return true if File.file?("#{app_config[location.to_sym]}/#{path}")
    errors.add(:path ,"Document doesn't exist on #{location_name}")
    false
  end

  def is_a_zip?
    is_zip = true
    if (/.zip$/.match(path)).blank?
      errors.add(:path ,"Document is not a zip file, cannot be extracted")
      is_zip = false
    end
    is_zip
  end

  def get_destination_folder_path(zip_file_link=nil)
      path = zip_file_link || get_doc_full_ftp_path
      File.dirname(path)
  end

  def unzip_document
    if !self.path.blank? && check_document_path
      zip_file_link    = get_doc_full_ftp_path
      destination_path = get_destination_folder_path(zip_file_link)

      puts "Extracting zip file '#{zip_file_link}' to '#{destination_path}'"
      Rails.logger.info "Extracting zip file '#{zip_file_link}' to '#{destination_path}'"

      begin
        if Dir.exists?(destination_path)
          FileUtils.chmod(0777, destination_path)
        end

        extract_stat = Archive::Zip.extract(zip_file_link, destination_path)
        if change_owner_and_mode(destination_path, extract_stat)
          msg = "Successfully changed the ownership and modes of extracted directory '#{destination_path}'"
          puts msg
          Rails.logger.info msg

          msg = "Extracted file '#{zip_file_link}' successfully."
          puts msg
          Rails.logger.info msg
          update_attributes(:status => STATUS[:unzipped])
          return true
        else
          error_msg = "Error in changing the ownership and modes of extracted directory '#{destination_path}'"
          puts error_msg
          Rails.logger.info error_msg
          update_unzip_status_failed(error_msg)
          return false
        end
      rescue => e
        error_msg ="Error in extracting file '#{zip_file_link}'. "
        puts error_msg
        Rails.logger.info error_msg
        Rails.logger.info e.inspect
        puts e.message
        update_unzip_status_failed("Error in extracting(unzipping) file : #{e.message}")
        return false
      end
    else
      error_msg = "Document is not a zip file (must have ''.zip' extension)."
      puts error_msg
      Rails.logger.info error_msg
      update_unzip_status_failed("Error in extracting(unzipping) file : #{error_msg}.")
      return false
    end
  end

  def change_owner_and_mode(full_path, stat=nil)
    if stat == nil
      # to change the file permissions/ownership and modes
      # Change unarchived director ownership and group to docsteam
      #username = ("#{app_config[:ftp_username]}")
      #groupname = ("#{app_config[:ftp_groupname]}")
      FileUtils.chown_R(app_config[:ftp_username], app_config[:ftp_groupname], full_path) unless Rails.env.localdev?

      #change directory mode to 0755
      ftp_chmod = (0775)
      FileUtils.chmod_R(ftp_chmod, full_path)
      puts File.stat(full_path).inspect
      Rails.logger.info File.stat(full_path).inspect
      return true
    else
      return false
    end
  end

  def update_unzip_status_failed(error_message = nil)
    update_attributes(:status => STATUS[:failed], :error_message => error_message)
  end

  def self.extract_zipped_files
    count = 0
    files = zipped_files
    processed_files = files.each {|f| f.update_attribute(:status, STATUS[:running])}
    files.each_with_index do |file, index|
      puts "Extracting file no #{index+1}"
      Rails.logger.info "Extracting file no #{index+1}"
      count += 1 if file.unzip_document
      #if file.delete
      #  Rails.logger.info "Deleted file no #{index+1}"
      #end
    end
    puts "-------------------------------------------------------"
    puts "Total #{count} files unzipped(extracted)"
    Rails.logger.info "Total #{count} files unzipped(extracted)"
  end

  def self.check_time_in_utc
    DateTime.now.ago(eval(app_config(:archive_file_time))).utc
  end
  def is_older_than_check_time?
    updated_at.utc < self.class.check_time_in_utc
  end

  def self.older_files
    DocFtp.where('updated_at < ?', check_time_in_utc)
  end

  def self.recent_files
    DocFtp.where('updated_at > ?', check_time_in_utc)
  end

  #Deletes all archive files entry which are unzipped 1 weeks(or app_config(:archive_file_time)) ago
  def self.delete_all_older_files
    older_files.delete_all
  end

end
