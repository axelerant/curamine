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

class ContactImportsControllerTest < ActionController::TestCase
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

    ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/',
                            [:contacts,
                             :contacts_projects,
                             :contacts_issues,
                             :deals,
                             :notes,
                             :roles,
                             :enabled_modules,
                             :tags,
                             :taggings,
                             :contacts_queries])


  def setup
    RedmineContacts::TestCase.prepare

    @controller = ContactImportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  test 'should open contact import form' do
    @request.session[:user_id] = 1
    get :new, :project_id => 1
    assert_response :success
    assert_select 'form.new_contact_import'
  end

  test 'should successfully import from CSV' do
    @request.session[:user_id] = 1
    assert_difference('Contact.count', 4, 'Should add 4 contacts to the database') do
      post :create, {
        :project_id => 1,
        :contact_import => {
          :file => Rack::Test::UploadedFile.new(fixture_files_path + "correct.csv", 'text/comma-separated-values'),
          :quotes_type => '"'
        }
      }
      assert_redirected_to project_contacts_path(:project_id => 1)
    end
  end
end
