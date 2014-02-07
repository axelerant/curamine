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

require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::ContactsTest < ActionController::IntegrationTest
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

    ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../../fixtures/',
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
    Setting.rest_api_enabled = '1'
    RedmineContacts::TestCase.prepare
  end

  def test_get_contacts_xml
    # Use a private project to make sure auth is really working and not just
    # only showing public issues.
    Redmine::ApiTest::Base.should_allow_api_authentication(:get, "/projects/private-child/contacts.xml")

    get '/contacts.xml', {}, credentials('admin')

    assert_tag :tag => 'contacts',
      :attributes => {
        :type => 'array',
        :total_count => assigns(:contacts_count),
        :limit => 25,
        :offset => 0
      }
  end


  def test_post_contacts_xml
    Redmine::ApiTest::Base.should_allow_api_authentication(:post,
                                    '/contacts.xml',
                                    {:contact => {:project_id => 1, :first_name => 'API test'}},
                                    {:success_code => :created})

    assert_difference('Contact.count') do
      post '/contacts.xml', {:contact => {:project_id => 1, :first_name => 'API test'}}, credentials('admin')
    end

    contact = Contact.first(:order => 'id DESC')
    assert_equal 'API test', contact.first_name

    assert_response :created
    assert_equal 'application/xml', @response.content_type
    assert_tag 'contact', :child => {:tag => 'id', :content => contact.id.to_s}
  end

  # Issue 6 is on a private project
  def test_put_contacts_1_xml
    parameters = {:contact => {:first_name => 'API update'}}

    Redmine::ApiTest::Base.should_allow_api_authentication(:put,
                                  '/contacts/1.xml',
                                  {:contact => {:first_name => 'API update'}},
                                  {:success_code => :ok})

    assert_no_difference('Contact.count') do
      put '/contacts/1.xml', parameters, credentials('admin')
    end

    contact = Contact.find(1)
    assert_equal "API update", contact.first_name

  end
  def test_should_post_with_custom_fields
    field = ContactCustomField.create!(:name => 'Test', :field_format => 'int')
    assert_difference('Contact.count') do
      post '/contacts.xml', {:contact => {:project_id => 1, :first_name => 'API test',
          :custom_fields => [{'id' => field.id.to_s, 'value' => '12' }]}}, credentials('admin')
    end
    contact = Contact.last
    assert_equal '12', contact.custom_value_for(field.id).value
  end

  def test_should_put_with_custom_fields
    field = ContactCustomField.create!(:name => 'Test', :field_format => 'text')
    assert_no_difference('Contact.count') do
      put '/contacts/1.xml', {:contact => {:custom_fields => [{'id' => field.id.to_s, 'value' => 'Hello' }]}}, credentials('admin')
    end
    contact = Contact.find(1)
    assert_equal 'Hello', contact.custom_value_for(field.id).value
  end

end
