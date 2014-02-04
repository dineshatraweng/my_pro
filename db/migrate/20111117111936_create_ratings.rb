class CreateRatings < ActiveRecord::Migration
  def self.up
    create_table :ratings do |t|
      t.decimal :rating
      t.references :product
      t.timestamps
    end
  end

  def self.down
    drop_table :ratings
  end
end
