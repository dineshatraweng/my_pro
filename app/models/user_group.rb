class UserGroup < ActiveRecord::Base
  has_many :user_domain_groups ,:dependent => :destroy
  has_many :user_domains , :through => :user_domain_groups
end
