class ModifyPfDatabase< ActiveRecord::Migration
  def self.up
    add_column :versions,:if_pf , :boolean, :null=>false, :default =>0
    add_column :issues,:if_pf , :boolean, :null=>false, :default=>0
    
    
    add_column :activities, :position, :integer,:null=>false, :default=>0
    add_column :actions, :position, :integer,:null=>false, :default=>0
    add_column :pf_tasks, :position, :integer,:null=>false, :default=>0
    add_column :process_models, :position, :integer,:null=>false, :default=>0
  end
  
  def self.down
    remove_column :versions,:if_pf , :boolean
    remove_column :issues,:if_pf  , :boolean
    
    remove_column :activities, :position, :integer
    remove_column :actions, :position, :integer
    remove_column :pf_tasks, :position, :integer
    remove_column :process_models, :position, :integer
  end  
end