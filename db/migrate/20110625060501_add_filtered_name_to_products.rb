# encoding: UTF-8

class AddFilteredNameToProducts < ActiveRecord::Migration 
  def self.up
    add_column :products, :filtered_name, :string

    products = Product.all
    products.each do |p|
      filtered_name = p.name.delete "™"
      filtered_name = filtered_name.delete "®"
      filtered_name = filtered_name.delete "©"
      p.update_attributes(:filtered_name => filtered_name)
    end
  end

  def self.down
    remove_column :products, :filtered_name
  end
end
