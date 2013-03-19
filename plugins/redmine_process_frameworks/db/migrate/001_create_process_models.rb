class CreateProcessModels < ActiveRecord::Migration
  def self.up
    create_table :process_models do |t|

      t.column :id, :integer , :null=>false

      t.column :name, :string , :null=>false

      t.column :description, :text

    end
  end

  def self.down
    drop_table :process_models
  end
end
