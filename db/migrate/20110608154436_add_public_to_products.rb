class AddPublicToProducts < ActiveRecord::Migration
  def self.up
    remove_column :documents, :public
    add_column :products, :public, :boolean, :default => false
  end

  def self.down
    remove_column :products, :public
    add_column :documents, :public, :boolean
  end
end
