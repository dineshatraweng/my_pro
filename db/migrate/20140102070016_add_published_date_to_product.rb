class AddPublishedDateToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :published_date, :datetime, :default => DateTime.now
  end

  def self.down
    remove_column :products, :published_date
  end
end
