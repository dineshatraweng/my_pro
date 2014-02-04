class AddOutOfCycleToDocument < ActiveRecord::Migration
  def self.up
    add_column :documents, :out_of_cycle, :datetime
  end
  def self.down
    remove_column :documents, :out_of_cycle
  end
end
