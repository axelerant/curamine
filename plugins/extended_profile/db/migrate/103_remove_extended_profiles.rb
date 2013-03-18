class RemoveExtendedProfiles < ActiveRecord::Migration

    def self.up
        drop_table :extended_profiles
    rescue
    end

end
