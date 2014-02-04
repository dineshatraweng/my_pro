class CreateDocumentDocTypes < ActiveRecord::Migration
  def self.up
    create_table :document_doc_types do |t|
      t.references :document
      t.references :doc_type
      t.timestamps
    end
  end

  def self.down
    drop_table :document_doc_types
  end
end
