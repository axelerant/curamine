class ModifyDatabase< ActiveRecord::Migration
  def self.up
    rename_column :actions, :type_id, :activity_id
    add_column :process_models,:date , :datetime,:default=>Time.now,:null=>false
    add_column :process_models,:author_id , :integer
    add_column :pf_attachments,:created_on , :datetime,:default=>Time.now,:null=>false
    add_column :pf_attachments,:author_id , :integer
  end
  
  def self.down
    rename_column :actions, :activity_id, :type_id
    remove_column :process_models,:date , :datetime
    remove_column :process_models,:author_id , :integer
    remove_column :pf_attachments,:created_on , :datetime
    remove_column :pf_attachments,:author_id , :integer
  end  
end