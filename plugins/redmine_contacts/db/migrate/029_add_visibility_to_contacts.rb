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

class AddVisibilityToContacts < ActiveRecord::Migration
  def up
    add_column :contacts, :visibility, :integer, :default => Contact::VISIBILITY_PROJECT, :null => false

    Contact.find_each(:batch_size => 1000) do |contact|
      contact.tag_list
      contact.save
    end

    ContactsSetting.all.each do |setting|
      setting.value = YAML::load(setting.value.respond_to?(:force_encoding) ? setting.value.force_encoding('utf-8') : setting.value) if setting.value.is_a?(String) rescue  ''
      setting.save!
    end
  end

  def down
    remove_column :contacts, :visibility
  end
end
