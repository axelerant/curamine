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

class CreateDeals < ActiveRecord::Migration
  def self.up
    create_table :deals do |t|
      t.string   :name
      t.text     :background
      t.integer  :currency
      t.integer  :duration
      t.decimal  :price, :precision => 10, :scale => 2
      t.integer  :price_type
      t.integer  :project_id
      t.integer  :author_id
      t.integer  :assigned_to_id
      t.integer  :status_id
      t.integer  :contact_id
      t.integer  :category_id
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :deals, :contact_id
    add_index :deals, :project_id
    add_index :deals, :status_id
    add_index :deals, :author_id
    add_index :deals, :category_id

  end

  def self.down
    drop_table :deals
  end
end
