class AddDoctypeToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :doctype, :string
  end

  def self.down
    remove_column :products, :doctype
  end
end
