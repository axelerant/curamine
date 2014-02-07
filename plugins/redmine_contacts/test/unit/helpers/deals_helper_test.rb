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

require File.expand_path('../../../test_helper', __FILE__)

class DealsHelperTest < ActionView::TestCase
  include ApplicationHelper
  include DealsHelper
  include CustomFieldsHelper
  include Redmine::I18n
  include ERB::Util

  fixtures :projects, :trackers, :issue_statuses, :issues,
           :enumerations, :users, :issue_categories,
           :versions,
           :projects_trackers,
           :member_roles,
           :members,
           :groups_users,
           :enabled_modules

  ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/',
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
    super
    set_language_if_valid('en')
    User.current = nil
  end

  def test_deals_to_csv
    csv_result = deals_to_csv(Deal.all)
    assert_match /Name/, csv_result
    assert_match /First deal with contacts/, csv_result
  end


  def test_deals_to_csv_with_multivalue_custom_field
    field = DealCustomField.create!(:name => 'filter', :field_format => 'list',
                                    :is_filter => true, :is_for_all => true,
                                    :possible_values => ['value1', 'value2', 'value3'],
                                    :multiple => true)
    deal = Deal.find(1)
    deal.custom_field_values = {field.id => ['value1', 'value2', 'value3']}
    deal.save!
    csv_result = deals_to_csv([deal])
    assert_match /Name/, csv_result
    assert_match /First deal with contacts/, csv_result
    assert_match /value1, value2, value3/, csv_result
  end


end
