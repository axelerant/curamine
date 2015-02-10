# encoding: utf-8
#
# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::ChecklistsTest < ActionController::IntegrationTest
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

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_checklists).directory + '/test/fixtures/',
                            [:checklists])

  def setup
    Setting.rest_api_enabled = '1'
  end

  def test_get_checklists_xml
    Redmine::ApiTest::Base.should_allow_api_authentication(:get, "/issues/1/checklists.xml")

    get '/issues/1/checklists.xml', {}, credentials('admin')

    assert_tag :tag => 'checklists',
      :attributes => {
        :type => 'array',
        :total_count => 2
      },
      :child => {
        :tag => 'checklist',
        :child => {
          :tag => 'id',
          :content => '1',
          :sibling => {
            :tag => 'subject',
            :content => 'First todo'
          }
        }
      }
  end

  def test_get_checklists_1_xml
    Redmine::ApiTest::Base.should_allow_api_authentication(:get, "/checklists/1.xml")

    get '/checklists/1.xml', {}, credentials('admin')

    assert_select 'checklist' do
      assert_select 'id', :text => '1'
      assert_select 'subject', :text => 'First todo'
    end
  end

  def test_post_checklists_xml
    parameters = {:checklist => {:issue_id => 1,
                                 :subject => 'api_test_001',
                                 :is_done => true}}
    Redmine::ApiTest::Base.should_allow_api_authentication(:post,
                                    '/issues/1/checklists.xml',
                                    parameters,
                                    {:success_code => :created})

    assert_difference('Checklist.count') do
      post '/issues/1/checklists.xml', parameters, credentials('admin')
    end

    checklist = Checklist.first(:order => 'id DESC')
    assert_equal parameters[:checklist][:subject], checklist.subject

    assert_response :created
    assert_equal 'application/xml', @response.content_type
    assert_tag 'checklist', :child => {:tag => 'id', :content => checklist.id.to_s}
  end

  def test_put_checklists_1_xml
    parameters = {:checklist => {:subject => 'Item_UPDATED'}}

    Redmine::ApiTest::Base.should_allow_api_authentication(:put,
                                  '/checklists/1.xml',
                                  parameters,
                                  {:success_code => :ok})

    assert_no_difference('Checklist.count') do
      put '/checklists/1.xml', parameters, credentials('admin')
    end

    checklist = Checklist.find(1)
    assert_equal parameters[:checklist][:subject], checklist.subject

  end

  def test_delete_1_xml
    assert_difference 'Checklist.count', -1 do
      delete '/checklists/1.xml', {}, credentials('admin')
    end

    assert_response :ok
    assert_equal '', @response.body
    assert_nil Checklist.find_by_id(1)
  end

end
