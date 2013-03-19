class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|

      t.column :id, :integer

      t.column :name, :string

      t.column :model_id, :integer

      t.column :description, :text

    end
  end

  def self.down
    drop_table :activities
  end
end
