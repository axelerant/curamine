class AddPercentAndDatesToMembers < ActiveRecord::Migration
  def self.up
    change_table :members do |t|
      t.integer :allocation, :null => false, :default => 0
      t.date :from_date
      t.date :to_date
    end
  end

  def self.down
    change_table :members do |t|
      t.remove :allocation
      t.remove :from_date
      t.remove :to_date
    end
  end
end
