class CreateDocFtps < ActiveRecord::Migration
  def self.up
    create_table :doc_ftps do |t|
      t.string  :name
      t.text    :path
      t.string  :doctype,  :default => DocFtp::DOCTYPE[:folder_path]
      t.string  :status,   :default => DocFtp::STATUS[:zipped]
      t.text    :error_message

      t.timestamps
    end
  end

  def self.down
    #drop_table :doc_ftps
  end
end
