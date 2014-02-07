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

class CreateTags < ActiveRecord::Migration
  def self.up
    unless ActsAsTaggableOn::Tag.table_exists?
      create_table :tags do |t|
        t.column :name, :string
      end
      add_index :tags, :name
    end

    unless ActsAsTaggableOn::Tagging.table_exists?
      create_table :taggings do |t|
        t.references :tag
        t.references :taggable, :polymorphic => true
        t.references :tagger, :polymorphic => true
        t.string :context, :limit => 128
        t.datetime :created_at
      end

      add_index :taggings, :tag_id
      add_index :taggings, [:taggable_id, :taggable_type, :context]
    end

  end

  def self.down
    drop_table :taggings
    drop_table :tags
  end
end
