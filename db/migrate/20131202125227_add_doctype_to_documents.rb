class AddDoctypeToDocuments < ActiveRecord::Migration

  def self.up
    add_column :documents, :doctype, :string, :default => Document::DOCTYPE[:folder_path]
  end

  def self.down
    remove_column :documents, :doctype
  end
end
