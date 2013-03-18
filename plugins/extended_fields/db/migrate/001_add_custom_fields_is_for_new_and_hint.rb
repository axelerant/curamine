class AddCustomFieldsIsForNewAndHint < ActiveRecord::Migration

    def self.up
        add_column :custom_fields, :is_for_new, :boolean, :default => true, :null => false
        add_column :custom_fields, :hint,       :string
    end

    def self.down
        remove_column :custom_fields, :is_for_new
        remove_column :custom_fields, :hint
    end

end
