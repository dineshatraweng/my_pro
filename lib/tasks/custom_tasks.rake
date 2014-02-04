namespace :pdf_count do
  task :all => :environment do
    desc "update pdf count column for all documents"
    products = Product.all                                                             #get all the products from the database
    unless products.empty?                                                             #only if we get any products form the database, proceed
      puts "Started updating....."
      fcounter=scounter = npdf= nexist= 0                                              #initialize the counters
      products.each do |product|                                                       #for each product in the product array
        documents = product.documents                                                  # collect all the documents of the current product
        unless documents.empty?                                                        # proceed only if product has any documents
          documents.each do |document|                                                 # for each document in documents array
            print "#{product.name} - #{document.name}: "
            result = document.check_document                                         # get the result of the update
            case result
              when 0                                                                   # 0 means the document was a pdf file and its count was updated successfully
                puts "success"
                scounter = scounter + 1
              when 1                                                                   # 1 means the document was not a pdf file and so no need
                puts "no (not a pdf)"
                npdf = npdf + 1
              when 2                                                                   # 2 means the document is a pdf but the specified path does not exist
                puts "no ( file does not exist)"
                nexist = nexist + 1
              when 4                                                                   # 4 means the document is a pdf but no updated in last 24 hrs so no pdf count is calculated
                puts "not updated within 24 hrs(no pdf count calculated )"
              when 7                                                                   # 4 means the document is a pdf but no updated in last 24 hrs so no pdf count is calculated
                puts "its located on Windows server "
              else                                                                     # 3 means the document is a pdf but the pdf count can not be updated because the file was not accessible
                puts "file not accessible"
                fcounter = fcounter + 1
            end
          end
        end
      end
      puts "================================================================"
      puts "Total records updated: #{scounter}"
      puts "Total bad file paths: #{nexist}"
      puts "Total non pdf files: #{npdf}"                                              # display the output
      puts "Total inaccessible file: #{fcounter}"
      puts "Thank you!"
      puts "================================================================"
    else
      puts "no product present to update the pdf count"
    end
  end 
end

task :set_product_slug => :environment do
  desc "update slug column for all existing products"
  puts "Updating all products to have user friendly id..."
  products = Product.all                           # get all the products
  scounter = fcounter = 0                          # initialize the counters
  unless products.empty?                           # proceed only if you have have any products
    products.each do |product|                     # for each product in products array
      print "#{product.name}: "
      begin
        ActiveRecord::Base.connection.execute("Insert into friendly_id_slugs(slug,sluggable_id,sluggable_type) values('#{product.id}','#{product.id}','product');")
        puts "#{product.save}"
        scounter  = scounter +1
      rescue => e
        puts "Error: #{e}"
        fcounter = fcounter + 1
      end

    end
  end
  puts "================================================================"
  puts "Total products updated: #{scounter}"
  puts "Total products not updated: #{fcounter}"
  puts "Thank you!"
  puts "================================================================"
end

task :daily_integrity_check ,[:argument]  => :environment  do |t,flag|
  desc "Create Archive for all Products, update pdf count column for all documents and send email to admin about urls integrity and archive files"
  @disable_update_check = @delete_archives = false
  @disable_update_check = true if flag.argument == "disable_update_check"
  @delete_archives = true if flag.argument == "delete_archives"

  puts "arguments =>[#{flag.argument}]: To disable update check pass \"disable_update_check \" as argument"
  products = Product.all.select{|product| !product.is_parent_product? }             # get all the products
  require 'csv'                      # reference : http://ruby-doc.org/stdlib-1.9.2/libdoc/csv/rdoc/CSV.html
  unless products.empty?             # proceed only if products exist in the array
    products_archive_del = products_archived = fcounter = nexist= 0           # initialize the counter
    recent_update_docs = Hash.new
    mail_string = archive_string = ""                 # initialize the mailing string
    mail_string += ['Product Name','Document Name','Document URL','Reason for failure'].to_csv # the string header

    puts "Started processing..."
    start_time =  DateTime.now
    task_start_time = DateTime.now.strftime('%H:%M:%S:%L')
    products.each do |product|                         # for each product in products array do the following
      puts product.name
      puts "Start time = #{DateTime.now.strftime('%Y-%m-%d %H:%M:%S:%L %z')}"
      ps =  DateTime.now.strftime('%H:%M:%S:%L')
      is_doc_modified = 0
      documents = product.documents                    # get all the documents of the current product
      archive_doc_arr = []                             # creating an empty array to hold documents to be zipped(archived) for download.
      unless documents.empty?                          # proceed only if the product has any documents
        list_of_updated_document = []
        doc = nil
        documents.each do |document|                   # for each document in the documents array
          doc = document
          result = document.check_document(product,start_time)             # get result of the update
          case result
            #when 1
            #  if (!document.check_document_path)
            #    mail_string +=["#{product.name}","#{document.name}","#{document.access_url(product)}"," Path does not exist "].to_csv
            #    nexist = nexist + 1
            #  end
            when 2
              mail_string +=["#{product.name}","#{document.name}","#{document.access_url(product)}"," Path does not exist "].to_csv
              nexist = nexist + 1
            when 3
              mail_string +=["#{product.name}","#{document.name}","#{document.access_url(product)}","File not accessible"].to_csv
              fcounter = fcounter + 1
            when 5
              mail_string +=["#{product.name}","#{document.name}","#{document.access_url(product)}","File is encrypted, cannot be accessed"].to_csv
              fcounter = fcounter + 1
          end
          unless result == 2 or result == 3
            unless result == 4                                                  # inc is_doc_modified, if doc updated within 24 hrs(1 day))
              is_doc_modified += 1
              list_of_updated_document.push(document.name)
            end

            if document.is_doctype_folder_path?
              unless document.is_a_index_html?
                doc_link = document.link
                archive_doc_arr << "#{app_config[:ftp_root]}/#{product.folder_path}/#{doc_link}"       # if doc link exists put in array for archive
              else
                doc_link = document.get_index_html_files
                unless doc_link == nil
                  archive_doc_arr << "#{app_config[:ftp_root]}/#{product.folder_path}/#{doc_link}"        # if doc link exists put in array for archive
                else
                  archive_string += "#{product.name},#{document.name},HTML files are not archived,ERROR => The Product folder and the html files(index.html) folder is same.\n"
                end
              end
            end
          end
        end
        if doc.check_product_updated(product)
          check_for_flag = true
          check_for = ["name","description","folder_path","public","visible"]
          observer_products = Audit.where("payload_id = ? AND updated_at >= ? AND updated_at <= ?",product.id,Time.now.utc - eval(app_config[:update_check_time]),Time.now.utc)
          observer_products.each do |ob_product|
            attributes = ob_product.modified_attributes.split(",")
            if attributes.any? {|attr| check_for.include?(attr) } and check_for_flag
              check_for_flag = false
              recent_update_docs["#{product.name}"] = list_of_updated_document.push("Product details has been changed")
              is_doc_modified += 1
            end
          end
        end
        recent_update_docs["#{product.name }"] = list_of_updated_document unless list_of_updated_document.empty?
      end

      if @delete_archives == true
        puts "Archive #{products_archive_del += 1} Deleted at = #{DateTime.now.strftime('%H:%M:%S:%L')}" if product.delete_archive
      elsif ((is_doc_modified >= 1 ) or @disable_update_check)  # check atleast one document is update within 24 hrs or update check is disabled by passing disable_update_check as args
        as = DateTime.now.strftime('%H:%M:%S:%L')
        puts "[ Archive Start = #{as}"
        if product.create_archive(archive_doc_arr)
          products_archived += 1
          ac = DateTime.now.strftime('%H:%M:%S:%L')
          puts "Archive #{products_archived} Completed at = #{ac}"
          puts "Archive Time = #{product.time_diff_in_ms(ac,as)} ms ]"
        else
          ac = DateTime.now.strftime('%H:%M:%S:%L')
          puts "Product not archived:  Time = #{product.time_diff_in_ms(ac,as)} ms ]"
        end
      end
      pc = DateTime.now.strftime('%H:%M:%S:%L')
      puts "Product completion time = #{DateTime.now.strftime('%Y-%m-%d %H:%M:%S:%L %z')}"
      puts "Product time taken = #{product.time_diff_in_ms(pc,ps)} ms"
      puts "\n"
    end
    puts "Total Products Archived = #{products_archived}"
    puts "Total Products Archived Deleted = #{products_archive_del}\n"
    task_end_time =  DateTime.now.strftime('%H:%M:%S:%L')
    puts "[Task Time => #{ products.first.time_diff_in_ms(task_end_time,task_start_time )} ms ]"

    params_n_attachments = {}
    if nexist == 0 && fcounter == 0
      params_n_attachments['no_broken_links'] = "No bad url found on the site."
    else
      dr_file = Tempfile.new(['broken_link_report','.csv'])
      dr_file.write mail_string
      dr_file.close
      params_n_attachments['broken_link_report'] = dr_file.path
    end

    params_n_attachments['products_archived_string'] = "Total Products Archived = #{products_archived}"
    unless archive_string.blank?
      ar_file = Tempfile.new(['archive_report','.txt'])
      ar_file.write(archive_string)
      ar_file.write("Total Products Archived = #{products_archived}")
      ar_file.close
      params_n_attachments['archive_report'] = ar_file.path
    end
    detailed_report = nil
    brief_report = nil
    latest_detail_report = nil
    latest_brief_report = nil
    category_report = nil
    ooc_report = nil
    ga_report = nil

    if Time.now.send("#{app_config(:report_day)}?")
      #if true
      detailed_report = Product.get_csv_reports_of_products({:id => "detailed"})
      brief_report = Product.get_csv_reports_of_products({:id => "brief"})
      latest_detail_report = Product.get_latest_detail_report
      latest_brief_report = Product.get_latest_brief_report
      category_report = Product.get_category_report
      ooc_report      = Product.out_of_cycle_report
      ga_report       = Product.get_ga_report
    end

    puts "sending email..."
    if detailed_report== nil or brief_report==nil
      UserMailer.send_weekly_report(params_n_attachments,detailed_report,brief_report,latest_detail_report,latest_brief_report,category_report,ooc_report, ga_report, recent_update_docs).deliver
    else
      UserMailer.send_weekly_report(params_n_attachments,detailed_report[0],brief_report[0],latest_detail_report[0],latest_brief_report[0],category_report[0],ooc_report[0],ga_report[0],recent_update_docs).deliver
    end

    puts "Finished. Thank you!!"
  end


end


task :sync_all_subjects_with_tibbr => :environment do
  desc 'This script creates subjects in tibbr based on the name of the Product and its type'
  begin
    TibbrIntegration.sync_with_tibbr
  rescue => e
    puts "Following Error has occurred:"
    puts "Exception Class: #{e.class}"
    puts "Message: #{e.message}"
    puts "Stack Trace: #{e.stack_trace}"
  else
    puts "Script Executed successfully"
  end
end

task :find_products_with_slash_folder_path => :environment do

  begin
    puts "***********************rake task begin**************************"
    all_products = Product.all
    child_product = all_products.select{|product| !product.is_parent_product? }
    child_product.each do |product|
      product_folder_path=[]
      product_folder_path= product.folder_path.split("/")
      correct_path =""
      append_slash = true
      product_folder_path.each  do |path|
        if path =="" and append_slash
          correct_path = correct_path + ""
        else
          append_slash = false
          unless path ==""
            correct_path =  correct_path + path + "/"
          end
        end
      end
      path =  correct_path[0..-2]
      product.update_attributes(:folder_path => path)
      puts product.inspect
    end
  rescue => e
    puts "*******************************got error while updating product path****************************************"
    puts e.inspect
  end
  puts "*********************************rake task completed successfully*********************************"
end


task :create_admin_user,[:username, :email, :password, :firstname, :lastname]  => :environment  do  |task, user|
  user = User.create(:username => user[:username], :email => user[:email], :firstname => user[:firstname], :lastname => user[:lastname], :password => user[:password], :password_confirmation => user[:password])
  if user.errors.any?
    puts "**********************************User not created*************************"
    puts user.errors.inspect
  else
    puts "**********************************User created successfully******************"
  end
end

task :update_admin_user_password,[:username,  :password]  => :environment  do  |task, user|
  puts "*********************************************"
  puts user[:username]
  admin_user = User.find_by_username(user[:username].to_s)
  admin_user.update_attributes(:password => user[:password] ,:password_confirmation => user[:password])
  puts "**********password updated successfully************************"
end

task :delete_admin_user,[:username]  => :environment  do  |task, user|
  admin_user = User.find_by_username(user[:username].to_s)
  admin_user.destroy
  puts "*********user deleted successfully*************************"
end

desc 'Delete Documents with doctype URL'
task :delete_documents_with_url_doctype => :environment do
  puts "Deleting Documents with doctype URL ..............."
  counts = Document.delete_all(:doctype => 'URL')
  puts "#{counts} No of documents deleted"
end

task :set_products_published_date => :environment do
  puts "Process Started.................."
  count = 0
  products = Product.all.each do |p|
    p.published_date = p.created_at
    if p.save(:validate=>false)
      count +=1
      puts "Product(id=#{p.id}) published_date updated successfully"
    else
      puts "Product(id=#{p.id}) published_date not updated "
      puts "Error: #{p.errors}"
    end
  end
  puts "#{count} Products published_date Updated"
end

task :remove_slash_from_folder_path => :environment do
  puts "Process Started.................."
  products = Product.where('folder_path like ?', "/%").each do |p|
    if p.save
      puts "Product(id=#{p.id}) folder_path updated successfully"
    else
      puts "Product(id=#{p.id}) folder_path not updated "
      puts "Error: #{p.errors}"
    end
  end
  puts "Products folder_path Updated"
end

task :remove_slash_from_document_link => :environment do
  puts "Process Started.................."
  documents = Document.where('link like ?', "/%").each do |d|
    if d.save
      puts "document(id=#{d.id}) document_link updated successfully"
    else
      puts "document(id=#{d.id}) document_link not updated "
      puts "Error: #{d.errors}"
    end
  end
  puts "Documents document_link Updated"
end

