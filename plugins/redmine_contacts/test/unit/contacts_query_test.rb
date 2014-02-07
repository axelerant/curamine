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

class ContactsQueryTest < ActiveSupport::TestCase
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


  def test_project_filter_in_global_queries
    User.current = User.find_by_login('admin')
    query = ContactsQuery.new(:project => nil, :name => '_')
    tags_filter = query.available_filters["tags"]
    assert_not_nil tags_filter
    assert tags_filter[:values].flatten.include?("main")
  end

  def find_contacts_with_query(query)
    Contact.find :all,
      :include => [ :projects, :notes ],
      :conditions => query.statement
  end

  def assert_find_contacts_with_query_is_successful(query)
    assert_nothing_raised do
      find_contacts_with_query(query)
    end
  end

  def assert_query_statement_includes(query, condition)
    assert query.statement.include?(condition), "Query statement condition not found in: #{query.statement}"
  end

  def assert_query_result(expected, query)
    assert_nothing_raised do
      assert_equal expected.map(&:id).sort, query.issues.map(&:id).sort
      assert_equal expected.size, query.issue_count
    end
  end


end
