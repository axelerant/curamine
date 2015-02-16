# encoding: utf-8
#
# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2015 RedmineCRM
# http://www.redminecrm.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class AgileQueriesControllerTest < ActionController::TestCase
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


  def test_get_index
    @request.session[:user_id] = 1
    get :index
    assert_response :success
    assert_template :index
  end

  def test_get_new
    @request.session[:user_id] = 1
    get :new
    assert_response :success
    assert_template :new
  end

  def test_get_edit
    @request.session[:user_id] = 1
    get :edit, :id => create_agile_query.id
    assert_response :success
    assert_template :edit
  end

  def test_post_create
    @request.session[:user_id] = 1
    params = {:query =>{:name => "Test",
                        :group_by => ""},
              :query_is_for_all => "1",
              :default_columns => "1",
              :f => ["status_id", ""],
              :op => {"status_id"=>"o"},
              :c => ["tracker", "assigned_to"]}
    if Redmine::VERSION.to_s < '2.4'
      params[:query][:is_public] = true
    else
      params[:query][:visibility] = "0"
    end
    assert_difference 'AgileQuery.count' do
      post :create, params
      assert_response :redirect
    end
  end

  def test_put_update
    @request.session[:user_id] = 1
    params = {:query =>{:name => "Test changed",
                        :group_by => ""},
              :id => create_agile_query.id}
    if Redmine::VERSION.to_s < '2.4'
      params[:query][:is_public] = true
    else
      params[:query][:visibility] = "0"
    end
    put :update, params
    assert_response :redirect
  end

private

  def create_agile_query
    query = AgileQuery.new(:name => 'Board for specific project',
                           :user_id => 1,
                           :project_id => 1,
                           :filters => {:tracker_id => {:values => ["3"], :operator => "="}})
    Redmine::VERSION.to_s < '2.4' ? query.is_public = false : query.visibility = 2
    query.save
    query
  end

end
