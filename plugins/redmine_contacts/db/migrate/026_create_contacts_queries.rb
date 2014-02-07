# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class CreateContactsQueries < ActiveRecord::Migration
  def self.up
    create_table :contacts_queries do |t|
      t.integer  :project_id
      t.string   :name,          :default => "",    :null => false
      t.text     :filters
      t.integer  :user_id,       :default => 0,     :null => false
      t.boolean  :is_public,     :default => false, :null => false
      t.text     :column_names
      t.text     :sort_criteria
      t.string   :group_by
      t.string   :type
    end
  end

  def self.down
    drop_table :contacts_queries
  end
end
