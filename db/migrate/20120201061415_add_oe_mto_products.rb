class AddOeMtoProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :oem, :boolean, :default => false
  end

  def self.down
    remove_column :products, :oem
  end
end
