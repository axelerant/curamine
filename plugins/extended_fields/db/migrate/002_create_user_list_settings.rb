class CreateUserListSettings < ActiveRecord::Migration

    def self.up
        create_table :user_list_settings do |t|
            t.column :user_id, :integer, :null => false
            t.column :list,    :string,  :null => false, :limit => 30
            t.column :columns, :text
        end
        add_index :user_list_settings, [ :user_id, :list ], :unique => true, :name => :settings_list_user_ids
    end

    def self.down
        drop_table :user_list_settings
    end

end
