class AddViewingMigration < ActiveRecord::Migration
  require 'acts_as_viewed'

  def self.up
    unless table_exists?(:viewings)
      ActiveRecord::Base.create_viewings_table
    end
  end

  def self.down    
    ActiveRecord::Base.drop_viewings_table
  end
end
