class AddVersionedToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :versioned, :boolean
    add_column :products, :version_no, :integer
    add_column :products, :order, :integer
  end

  def self.down
    remove_column :products, :order
    remove_column :products, :version_no
    remove_column :products, :versioned
  end
end
