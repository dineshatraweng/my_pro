class CreateDocTypes < ActiveRecord::Migration
  def self.up
    create_table :doc_types do |t|
      t.string :doctype

      t.timestamps
    end
  end

  def self.down
    drop_table :doc_types
  end
end
