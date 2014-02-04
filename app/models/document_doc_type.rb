class DocumentDocType < ActiveRecord::Base
  belongs_to :document
  belongs_to :doc_type
end
