class ModifyRedmineDatabase< ActiveRecord::Migration
  def self.up
    add_column :projects,:if_config_pf , :boolean, :default =>0,:null=>false
    add_column :projects,:model_id , :integer
  end
  
  def self.down
    remove_column :projects,:if_config_pf , :boolean
    remove_column :projects,:model_id  , :integer
  end  
end