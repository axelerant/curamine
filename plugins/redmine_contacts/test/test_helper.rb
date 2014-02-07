# encoding: utf-8
#
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

require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

def fixture_files_path
  "#{File.expand_path('..',__FILE__)}/fixtures/files/"
end

# Engines::Testing.set_fixture_path

class RedmineContacts::TestCase
  include ActionDispatch::TestProcess
  def self.plugin_fixtures(plugin, *fixture_names)
    plugin_fixture_path = "#{Redmine::Plugin.find(plugin).directory}/test/fixtures"
    if fixture_names.first == :all
      fixture_names = Dir["#{plugin_fixture_path}/**/*.{yml}"]
      fixture_names.map! { |f| f[(plugin_fixture_path.size + 1)..-5] }
    else
      fixture_names = fixture_names.flatten.map { |n| n.to_s }
    end

    ActiveRecord::Fixtures.create_fixtures(plugin_fixture_path, fixture_names)
  end

  def uploaded_test_file(name, mime)
    ActionController::TestUploadedFile.new(ActiveSupport::TestCase.fixture_path + "/files/#{name}", mime, true)
  end

  def self.is_arrays_equal(a1, a2)
    (a1 - a2) - (a2 - a1) == []
  end

  def self.prepare
    # User 2 Manager (role 1) in project 1, email jsmith@somenet.foo
    # User 3 Developer (role 2) in project 1


    Role.find(1, 2, 3, 4).each do |r|
      r.permissions << :view_contacts
      r.save
    end

    Role.find(1, 2).each do |r|
      #user_2, user_3
      r.permissions << :add_contacts
      r.save
    end

    Array(Role.find(1)).each do |r|
      #user_2
      r.permissions << :add_deals
      r.permissions << :save_contacts_queries
      r.save
    end

    Role.find(1, 2).each do |r|
      r.permissions << :edit_contacts
      r.save
    end
    Role.find(1, 2, 3).each do |r|
      r.permissions << :view_deals
      r.save
    end

    Role.find(2) do |r|
      r.permissions << :edit_deals
      r.save
    end

    Role.find(1, 2).each do |r|
      r.permissions << :manage_public_contacts_queries
      r.save
    end

    Project.find(1, 2, 3, 4, 5).each do |project|
      EnabledModule.create(:project => project, :name => 'contacts')
    end
  end

end
