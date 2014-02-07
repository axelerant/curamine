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

require File.expand_path('../../test_helper', __FILE__)

class ContactsSettingsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :versions,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :time_entries

    ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/',
                            [:contacts,
                             :contacts_projects,
                             :contacts_issues,
                             :deals,
                             :notes,
                             :tags,
                             :taggings,
                             :contacts_queries])

  def setup
    RedmineContacts::TestCase.prepare
    @controller = ContactsSettingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  test "should save setting" do
    @request.session[:user_id] = 1
    post :save, :project_id => 1, :contacts_settings => {:setting1 => 1, :setting2 => "Hello"}, :tab => 'contacts'
    assert_redirected_to :controller => 'projects', :action => 'settings', :tab => 'contacts', :id => "ecookbook"
    assert_equal "1", ContactsSetting[:setting1, 1]
    assert_equal "Hello", ContactsSetting[:setting2, 1]
  end

end
