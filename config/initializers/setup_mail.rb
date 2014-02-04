ActionMailer::Base.smtp_settings = {
  :address        => app_config(:smtp_settings, :address),
  :port           => app_config(:smtp_settings, :port),
  :user_name      => app_config(:smtp_settings, :username),
  :password       => app_config(:smtp_settings, :password),
  :domain         => app_config(:smtp_settings, :domain),
  :authentication => app_config(:smtp_settings, :authentication),
  :enable_starttls_auto => app_config(:smtp_settings, :enable_starttls_auto),
}