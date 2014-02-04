class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.string      :name
      t.text        :description
      t.string      :version_number
      t.text        :folder_path
      t.references  :product
      t.timestamps
    end
  end

  def self.down
    drop_table :versions
  end
end
