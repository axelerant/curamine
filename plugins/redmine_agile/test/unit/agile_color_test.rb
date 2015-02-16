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

class AgileColorTest < ActiveSupport::TestCase
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
  def test_save_color
    issue = Issue.find(1)
    assert_nil issue.color
    issue.agile_color.color = AgileColor::AGILE_COLORS[:red]
    assert issue.save
    issue.reload
    assert_equal AgileColor::AGILE_COLORS[:red], issue.color
  end

  def test_delete_color
    issue = Issue.find(1)
    assert_nil issue.color
    issue.agile_color.color = AgileColor::AGILE_COLORS[:red]
    assert issue.save
    issue.reload
    color = issue.agile_color
    assert issue.destroy
    assert !AgileColor.exists?(color)
  end
end
