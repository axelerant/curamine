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

# encoding: utf-8
require File.expand_path('../../../test_helper', __FILE__)


class ContactsProjectSettingTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/',
                            [:contacts,
                             :contacts_projects,
                             :contacts_issues,
                             :contacts_settings,
                             :deals,
                             :notes,
                             :tags,
                             :taggings,
                             :contacts_queries])

  def setup
    @project_settings = ContactsProjectSetting.new(Project.find(1), "redmine_contacts")
  end

  def test_read_values
    assert_equal "String value", @project_settings.string_setting
    assert_equal true, @project_settings.boolean_setting?
  end

  def test_read_global_values
    Setting["plugin_redmine_contacts"]["global_value"] = "Global"
    assert_equal "Global", @project_settings.global_value
  end

  def test_read_default_values
    assert_equal ["USD", "EUR", "GBP", "RUB", "CHF"].sort, @project_settings.major_currencies.sort
  end

  def test_read_default_values_post_address_format
    assert_equal "%street1%\n%street2%\n%city%, %postcode%\n%region%\n%country%", @project_settings.post_address_format
  end

end
