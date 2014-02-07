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

class ContactsTagsControllerTest < ActionController::TestCase
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
                             :tags,
                             :taggings,
                             :contacts_queries])

  def setup
    RedmineContacts::TestCase.prepare

    @controller = ContactsTagsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil

    @request.env['HTTP_REFERER'] = '/'
  end

  test "should get edit" do
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:tag)
    assert_equal ActsAsTaggableOn::Tag.find(1), assigns(:tag)
  end

  test "should put update" do
    @request.session[:user_id] = 1
    tag1 = ActsAsTaggableOn::Tag.find(1)
    old_name = tag1.name
    new_name = "updated main"
    put :update, :id => 1, :tag => {:name => new_name, :color_name=>"#000000"}
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => "redmine_contacts", :tab => "tags"
    tag1.reload
    assert_equal new_name, tag1.name
  end

  test "should delete destroy" do
    @request.session[:user_id] = 1
    assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
      post :destroy, :id => 1
      assert_response 302
    end
  end

  test "should get merge" do
    @request.session[:user_id] = 1
    tag1 = ActsAsTaggableOn::Tag.find(1)
    tag2 = ActsAsTaggableOn::Tag.find(2)
    get :merge, :ids => [tag1.id, tag2.id]
    assert_response :success
    assert_template 'merge'
    assert_not_nil assigns(:tags)
  end

  test "should post merge" do
    @request.session[:user_id] = 1
    tag1 = ActsAsTaggableOn::Tag.find(1)
    tag2 = ActsAsTaggableOn::Tag.find(2)
    assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
      post :merge, :ids => [tag1.id, tag2.id], :tag => {:name => "main"}
      assert_redirected_to :controller => 'settings', :action => 'plugin', :id => "redmine_contacts", :tab => "tags"
    end
    assert_equal 0, Contact.tagged_with("test").count
    assert_equal 4, Contact.tagged_with("main").count
  end

end
