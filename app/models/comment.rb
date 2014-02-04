class Comment < ActiveRecord::Base
  has_ancestry
  belongs_to :product

  validates_presence_of :content
end
