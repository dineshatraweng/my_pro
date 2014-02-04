class AddVisibleToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :visible, :boolean, :default => true
  end

  def self.down
    remove_column :products, :visible
  end
end
