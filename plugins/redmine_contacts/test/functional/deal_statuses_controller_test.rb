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

class DealStatusesControllerTest < ActionController::TestCase
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
  # Replace this with your real tests.

    ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/',
                            [:contacts,
                             :contacts_projects,
                             :contacts_issues,
                             :deals,
                             :deal_statuses,
                             :notes,
                             :tags,
                             :taggings,
                             :contacts_queries])

  def setup
    RedmineContacts::TestCase.prepare

    @controller = DealStatusesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_index_by_anonymous_should_redirect_to_login_form
    @request.session[:user_id] = nil
    get :index
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fdeal_statuses'
  end

  test "should get new" do
    @request.session[:user_id] = 1
    get :new
    assert_response :success
    assert_template 'new'
    # assert_not_nil Issue.find_by_subject("test subject")
  end

  test "should get edit" do
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:deal_status)
    assert_equal DealStatus.find(1), assigns(:deal_status)
  end

  test "should post update" do
    @request.session[:user_id] = 1
    status1 = DealStatus.find(1)
    old_name = status1.name
    new_name = "updated main"
    put :update, :id => 1, :deal_status => {:name => new_name, :color_name=>"#000000"}
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => "redmine_contacts", :tab => "deal_statuses"
    status1.reload
    assert_equal new_name, status1.name
  end

  def test_assing_to_project
    @request.session[:user_id] = 1
    put :assing_to_project, :deal_statuses => ["1", "2"], :project_id => "ecookbook"
    assert_redirected_to :controller => 'projects', :action => 'settings', :tab => 'deals', :id => "ecookbook"
  end

  def test_destroy
    @request.session[:user_id] = 1
    Deal.delete_all("status_id = 1")

    assert_difference 'DealStatus.count', -1 do
      delete :destroy, :id => '1'
    end
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => "redmine_contacts", :tab => "deal_statuses"
    assert_nil DealStatus.find_by_id(1)
  end

  def test_destroy_should_block_if_status_in_use
    @request.session[:user_id] = 1
    assert_not_nil Deal.find_by_status_id(1)

    assert_no_difference 'DealStatus.count' do
      delete :destroy, :id => '1'
    end
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => "redmine_contacts", :tab => "deal_statuses"
    assert_not_nil DealStatus.find_by_id(1)
  end

end
