class DocType < ActiveRecord::Base

#  has_many :document_doc_types, :dependent => :destroy
#  has_many :documents, :through => :document_doc_types

  has_many :documents
  validates_presence_of :doctype
end
