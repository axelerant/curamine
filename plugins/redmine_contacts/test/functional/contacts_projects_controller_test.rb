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

class ContactsProjectsControllerTest < ActionController::TestCase
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
    @controller = ContactsProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  test "should delete project" do
    @request.session[:user_id] = 1
    contact = Contact.find(1)
    assert_equal 2, contact.projects.size
    xhr :delete, :delete, :project_id => 1, :related_project_id => 2, :contact_id => 1
    assert_response :success
    assert_include 'contact_projects', response.body

    contact.reload
    assert_equal [1], contact.project_ids
  end

  test "should not delete last project" do
    @request.session[:user_id] = 1
    contact = Contact.find(1)
    assert RedmineContacts::TestCase.is_arrays_equal(contact.project_ids, [1, 2])
    # assert_equal '12', "#{contact.project_ids} || #{contact.projects.map(&:name).join(', ')} #{Project.find(1).contacts.map(&:name).join(', ')},  #{Project.find(2).name}"
    xhr :delete, :delete, :project_id => 1, :related_project_id => 2, :contact_id => 1
    assert_response :success
    xhr :delete, :delete, :project_id => 1, :related_project_id => 1, :contact_id => 1
    assert_response 403

    contact.reload
    assert_equal [1], contact.project_ids
  end

  test "should add project" do
    @request.session[:user_id] = 1

    xhr :post, :add, :project_id => "ecookbook", :related_project_id => 2, :contact_id => 2
    assert_response :success
    assert_include 'contact_projects', response.body
    contact = Contact.find(2)
    assert RedmineContacts::TestCase.is_arrays_equal(contact.project_ids, [1, 2])
  end

  test "should not add project without contacts module" do
    @request.session[:user_id] = 1

    xhr :post, :add, :project_id => "project6", :related_project_id => 2, :contact_id => 2
    assert_response 403
  end



end
