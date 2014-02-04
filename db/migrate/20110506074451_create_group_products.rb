class CreateGroupProducts < ActiveRecord::Migration
  def self.up
    create_table :group_products do |t|
      t.references :group
      t.references :product

      t.timestamps
    end
  end

  def self.down
    drop_table :group_products
  end
end
