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

class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.string   :first_name
      t.string   :last_name
      t.string   :middle_name
      t.string   :company
      t.text     :address
      t.string   :phone
      t.string   :email
      t.string   :website
      t.string   :skype_name
      t.date     :birthday
      t.string   :avatar
      t.text     :background
      t.string   :job_title
      t.boolean  :is_company,     :default => false
      t.integer  :author_id,      :default => 0,     :null => false
      t.integer  :assigned_to_id
      t.datetime :created_on
      t.datetime :updated_on
    end

    add_index :contacts, :author_id
    add_index :contacts, :is_company
    add_index :contacts, :company
    add_index :contacts, :first_name
    add_index :contacts, :assigned_to_id

  end

  def self.down
    drop_table :contacts
  end
end
