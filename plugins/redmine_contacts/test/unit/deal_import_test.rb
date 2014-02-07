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

class DealImportTest < ActiveSupport::TestCase
    fixtures :projects, :users

    ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/',
                            [:contacts,
                             :contacts_projects,
                             :deals,
                             :deal_statuses,
                             :deal_categories,
                             :roles,
                             :enabled_modules])

  def fixture_files_path
    "#{File.expand_path('../..',__FILE__)}/fixtures/files/"
  end

  def test_open_correct_csv
    deal_import = DealImport.new(
      :file => Rack::Test::UploadedFile.new(fixture_files_path + "deals_correct.csv", 'text/comma-separated-values'),
      :project => Project.first,
      :quotes_type => '"'
      )
    assert_difference('Deal.count', 1, 'Should have 1 deal in the database') do
      assert_equal 1, deal_import.imported_instances.count, 'Should find 1 deal in file'
      assert deal_import.save, 'Should save successfully'
    end
    deal = Deal.last
    assert_equal 2, deal.status_id, "Status doesn't mach"
    assert_equal 1, deal.category_id, "Category should be Design"
    assert_equal 'rhill', deal.assigned_to.login, "Assignee should be rhill"
  end
end
