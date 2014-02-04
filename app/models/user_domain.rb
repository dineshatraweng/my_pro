class UserDomain < ActiveRecord::Base
  has_many :user_domain_groups ,:dependent => :destroy
  has_many :user_groups, :through => :user_domain_groups

  validates_presence_of :name
  validates_uniqueness_of :name, { case_sensitive: false }

  def self.authenticated_emails
    eval app_config(:user_domains, :emails)
  end

  def self.authenticated_password
    app_config(:user_domains, :password)
  end

  def self.authenticate_access(authentication_data)
    return false if authentication_data.blank?
    return authenticated_emails.include?(authentication_data[:email]) && authenticated_password == authentication_data[:password]
  end
end
