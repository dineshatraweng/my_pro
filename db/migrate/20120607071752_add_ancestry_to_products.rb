class AddAncestryToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :ancestry, :string
    add_index :products, :ancestry
  end

  def self.down
    remove_column :products, :ancestry
    remove_index :products, :ancestry
  end
end
