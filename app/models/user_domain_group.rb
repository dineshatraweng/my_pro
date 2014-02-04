class UserDomainGroup < ActiveRecord::Base
  belongs_to :user_domain
  belongs_to :user_group
end
