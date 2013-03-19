class CreatePfAttachments < ActiveRecord::Migration
  def self.up
    create_table :pf_attachments do |t|

      t.column :id, :integer , :null=>false

      t.column :foreign_id, :integer ,:null => false

      t.column :type,     :string, :limit=>16, :null=>false
      
      t.column :filename, :string
      
      t.column :disk_filename, :string 

      t.column :filesize, :integer , :default=>0

      t.column :description, :text

    end
  end

  def self.down
    drop_table :task_attachments
  end
end
