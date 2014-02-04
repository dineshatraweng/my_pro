task :extract_zip_files => :environment do
  desc "Extract unzip zip files from DocFtp tables"

  puts "Start Unzipping files."
  Rails.logger.info "Start Unzipping files."
  DocFtp.extract_zipped_files
  puts "Completed Unzipping files."
  Rails.logger.info "Completed Unzipping files."

  puts "Delete Older Files entry."
  Rails.logger.info "Delete Older Files entry."
  file_count = DocFtp.delete_all_older_files
  puts "Total #{file_count} Files Deleted."
  Rails.logger.info "Total #{file_count} Files Deleted."

end