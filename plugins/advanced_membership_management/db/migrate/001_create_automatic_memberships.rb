class CreateAutomaticMemberships < ActiveRecord::Migration
  def change
    create_table :automatic_memberships do |t|
      t.references :user, :null => false
    end
    add_index :automatic_memberships, :user_id
  end
end
