class CreateCannedResponses < ActiveRecord::Migration
  def change
    create_table :canned_responses do |t|
      t.string :name
      t.text :content
      t.integer :project_id
      t.integer :user_id
      t.boolean :is_public
    end
  end
end
