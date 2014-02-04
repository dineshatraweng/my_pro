class AddDefaultToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :default, :boolean, :default => false
  end

  def self.down
    remove_column :products, :default
  end
end
