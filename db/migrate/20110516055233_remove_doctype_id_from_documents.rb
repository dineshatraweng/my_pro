class RemoveDoctypeIdFromDocuments < ActiveRecord::Migration
  def self.up
    remove_column :documents, :doctype_id
  end

  def self.down
    add_column :documents, :doctype_id, :string
  end
end
