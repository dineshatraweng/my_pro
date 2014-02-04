class UserMailer < ActionMailer::Base
  def send_weekly_report(mail_file={},detailed_report=nil,brief_report=nil ,latest_detail_report = nil , latest_brief_report = nil , category_report = nil ,ooc_report = nil, ga_report = nil, recent_update_doc = nil)
    @no_broken_links = mail_file['no_broken_links'] if mail_file.has_key?('no_broken_links')
    @products_archived_string = mail_file['products_archived_string'] if mail_file.has_key?('products_archived_string')
    @recent_update_docs = recent_update_doc
    @mail_message = ""
    broken_link_report = mail_file.has_key?('broken_link_report')  # mail_file has file attachment about broken link i.e broken_link_report
    archive_report = mail_file.has_key?('archive_report')          # mail_file has file attachment about file archives link i.e archive_report
    @docs_url = app_config(:docs,:url)
    @mail_message = "Find the attached report about broken links on the site(#{@docs_url})." if broken_link_report
    @mail_message = "Find the attached report about archived products on the site(#{@docs_url})." if archive_report
    @mail_message = "Find the attached report about broken links and archived products on the site(#{@docs_url})." if broken_link_report and archive_report


    attachments["Broken_link_report_#{Date.today.strftime('%Y_%m_%d')}.csv"] = File.read(mail_file['broken_link_report']) if broken_link_report
    attachments["Archive_report_#{Date.today.strftime('%Y_%m_%d')}.txt"] = File.read(mail_file['archive_report']) if archive_report

    if detailed_report != nil or brief_report != nil or latest_detail_report != nil
      @temp_dir ||= begin
        require 'tmpdir'
        require 'fileutils'
        called_from = File.basename caller.first.split(':').first, ".rb"
        path = File.join(Dir::tmpdir, "#{called_from}_#{Time.now.to_i}_#{rand(1000)}")
        Dir.mkdir(path)
        File.open(path+'/detailed.csv', "w+b", 0644) do |f|
          f.puts  detailed_report
        end
        File.open(path+'/brief.csv', "w+b", 0644) do |f|
          f.puts  brief_report
        end

        File.open(path + '/latest_detail_report.csv' , "w+b" , 0644) do |f|
          f.puts   latest_detail_report
        end

        File.open(path + '/latest_brief_report.csv' , "w+b" , 0644) do |f|
          f.puts latest_brief_report
        end

        File.open(path + '/category_report.csv' , "w+b" , 0644) do |f|
          f.puts category_report
        end

        File.open(path + '/out_of_cycle_update.csv' , "w+b" , 0644) do |f|
          f.puts ooc_report
        end

        File.open(path + '/hold_untill_ga_report.csv' , "w+b" , 0644) do |f|
          f.puts ga_report
        end

        attachments["detailed_report_#{Date.today.strftime('%Y_%m_%d')}.csv"] = File.read(path+'/detailed.csv')
        attachments["brief_report_#{Date.today.strftime('%Y_%m_%d')}.csv"] = File.read(path+'/brief.csv')
        attachments["latest_releases_detail_report_#{Date.today.strftime('%Y_%m_%d')}.csv"] = File.read(path + '/latest_detail_report.csv')
        attachments["latest_releases_brief_report_#{Date.today.strftime('%Y_%m_%d')}.csv"] =  File.read(path + '/latest_brief_report.csv')
        attachments["product_breadcrumb_report_#{Date.today.strftime('%Y_%m_%d')}.csv"] = File.read(path + '/category_report.csv')
        attachments["out_of_cycle_update_#{Date.today.strftime('%Y_%m_%d')}.csv"] = File.read(path + '/out_of_cycle_update.csv')
        attachments["hold_untill_ga_report_#{Date.today.strftime('%Y_%m_%d')}.csv"] = File.read(path + '/hold_untill_ga_report.csv')

        mail(:from => "\"TIBCO Docsite\"<#{app_config(:smtp_settings,:username)}>",
             :to => app_config(:admin,:email),
             :subject => "TIBCO Docsite: Daily Report: #{Date.today.strftime('%d %b %Y')}" ,

        )
        File.delete(path + '/detailed.csv')
        File.delete(path + '/brief.csv')
        File.delete(path + '/latest_detail_report.csv')
        File.delete(path + '/latest_brief_report.csv')
        File.delete(path + '/category_report.csv')
        File.delete(path + '/out_of_cycle_update.csv')
        File.delete(path + '/hold_untill_ga_report.csv')
      end
    else

      mail(:from => "\"TIBCO Docsite\"<#{app_config(:smtp_settings,:username)}>",
           :to => app_config(:admin,:email),
           :subject => "TIBCO Docsite: Daily Report: #{Date.today.strftime('%d %b %Y')}")
    end
  end

  def send_error_in_tibbr_mail(error_details,tibber_error_details,details=nil)
    @tibber_errors = tibber_error_details
    @error_details = error_details
    @details =  details
    if Rails.env == 'production'
      subject =  "TIBCO Docsite: Error Report:  #{Date.today.strftime('%d %b %Y')}"
    else
      subject = "TIBCO Docsite: Error Report:( #{Rails.env}) #{Date.today.strftime('%d %b %Y')}"
    end
    mail(:from => "\"TIBCO Docsite\"<#{app_config(:smtp_settings,:username)}>",
         :to => app_config(:admin,:raw_team),
         :subject => subject )
  end
end
