class ChangeVersionNoToString < ActiveRecord::Migration
  def self.up
    change_column :products, :version_no,:string
  end

  def self.down
    change_column :products, :version_no, :integer
  end
end
