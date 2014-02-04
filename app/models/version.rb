class Version < ActiveRecord::Base
  belongs_to :product

  validates_presence_of :name
  validates_presence_of :version_number
  validates_presence_of :folder_path
end
