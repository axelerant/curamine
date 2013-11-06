class CreateAutomaticMembershipRoles < ActiveRecord::Migration
  def change
    create_table :automatic_membership_roles do |t|
      t.references :automatic_membership, :null => false
      t.references :role, :null => false
    end
    add_index :automatic_membership_roles, :automatic_membership_id
    add_index :automatic_membership_roles, :role_id
  end
end
