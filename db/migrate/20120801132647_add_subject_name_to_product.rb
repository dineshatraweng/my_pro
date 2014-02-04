class AddSubjectNameToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :subject_name, :string
  end

  def self.down
    remove_column :products, :subject_name
  end
end
