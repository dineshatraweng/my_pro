class CreateParentGroups < ActiveRecord::Migration
  def self.up
    create_table :parent_groups do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :parent_groups
  end
end
