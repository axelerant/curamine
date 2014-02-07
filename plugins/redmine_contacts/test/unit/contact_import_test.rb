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

class ContactImportTest < ActiveSupport::TestCase
  fixtures :projects, :users

  def test_open_correct_csv
    contact_import = ContactImport.new(
      :file => Rack::Test::UploadedFile.new(fixture_files_path + "correct.csv", 'text/comma-separated-values'),
      :project => Project.first,
      :quotes_type => '"'
      )
    puts contact_import.errors.full_messages unless contact_import.valid?
    assert_equal 4, contact_import.imported_instances.count, 'Should find 4 contacts in file'
    assert contact_import.save, 'Should save successfully'
  end

  def test_should_report_error_line
    contact_import = ContactImport.new(
      :file => Rack::Test::UploadedFile.new(fixture_files_path + "with_data_malformed.csv", 'text/comma-separated-values'),
      :project => Project.first,
      :quotes_type => '"'
      )
    assert !contact_import.save, 'Should not save with malformed date'
    assert_equal 1, contact_import.errors.count, 'Should have 1 error'
    assert contact_import.errors.first.last.include?("Error on line 1"), 'Should mention string number in error message'
  end

  def test_open_csv_with_custom_fields
    cf1 = ContactCustomField.create!(:name => 'License', :field_format => 'string')
    cf2 = ContactCustomField.create!(:name => 'Purchase date', :field_format => 'date')
    contact_import = ContactImport.new(
      :file => Rack::Test::UploadedFile.new(fixture_files_path + "contacts_cf.csv", 'text/comma-separated-values'),
      :project => Project.first,
      :quotes_type => '"'
      )
    assert_equal 1, contact_import.imported_instances.count, 'Should find 1 contact in file'
    assert contact_import.save, 'Should save successfully'
    assert_equal "12345", Contact.find_by_first_name('Monica').custom_field_value(cf1.id)
    assert_equal "rhill", Contact.find_by_first_name('Monica').assigned_to.login
  end

end
