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

class CreateDealsRelations < ActiveRecord::Migration
  def self.up
    create_table :deal_categories do |t|
      t.string  :name,       :null => false
      t.integer :project_id
    end
    add_index :deal_categories, :project_id

    create_table :deal_processes do |t|
      t.integer  :deal_id,    :null => false
      t.integer  :author_id,  :null => false
      t.integer  :old_value
      t.integer  :value,      :null => false
      t.datetime :created_at
    end
    add_index :deal_processes, [:author_id]
    add_index :deal_processes, [:deal_id]

    create_table :deal_statuses do |t|
      t.string  :name,                             :null => false
      t.integer :position
      t.boolean :is_default, :default => false,    :null => false
      t.boolean :is_closed,  :default => false,    :null => false
      t.integer :color,      :default => 11184810, :null => false
    end
    add_index :deal_statuses, [:is_closed]

    create_table :deal_statuses_projects, :id => false do |t|
      t.integer :project_id,     :default => 0, :null => false
      t.integer :deal_status_id, :default => 0, :null => false
    end
    add_index :deal_statuses_projects, [:project_id, :deal_status_id]

  end

  def self.down
    drop_table :deal_categories
    drop_table :deal_processes
    drop_table :deal_statuses
    drop_table :deal_statuses_projects
  end
end
