class CreateAudits < ActiveRecord::Migration
  def self.up
    create_table :audits do |t|
      t.integer :payload_id
      t.string :payload_type
      t.integer :user_id
      t.text :payload_json
      t.text :modified_attributes
      t.timestamps
    end
  end

  def self.down
    drop_table :audits
  end
end
