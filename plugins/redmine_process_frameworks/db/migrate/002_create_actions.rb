class CreateActions < ActiveRecord::Migration
  def self.up
    create_table :actions do |t|

      t.column :id, :integer , :null=> false

      t.column :type_id, :integer 

      t.column :name, :string 

      t.column :description, :text

    end
  end

  def self.down
    drop_table :actions
  end
end
