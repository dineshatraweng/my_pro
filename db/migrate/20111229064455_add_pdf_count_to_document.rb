class AddPdfCountToDocument < ActiveRecord::Migration
  def self.up
    add_column :documents, :pdf_count, :integer
  end

  def self.down
    remove_column :documents, :pdf_count
  end
end
