class ChangeRatingToFloat < ActiveRecord::Migration
  

  def self.up
    change_column :ratings, :rating , :float
  end

  def self.down
    change_column :ratings, :rating , :decimal
  end
end
