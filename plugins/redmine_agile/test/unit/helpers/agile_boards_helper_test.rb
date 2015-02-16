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

require File.expand_path('../../../test_helper', __FILE__)

class AgileBoardsHelperTest < ActiveSupport::TestCase
  include ApplicationHelper
  include AgileBoardsHelper
  include CustomFieldsHelper
  include ActionView::Helpers::TagHelper
  include Redmine::I18n
  include ERB::Util

  def setup
    super
    set_language_if_valid('en')
    User.current = nil
  end

  def test_render_board_headers_flat
    columns = [
      status_1 = IssueStatus.create(:name => "ToDo"),
      status_2 = IssueStatus.create(:name => "Doing"),
      status_3 = IssueStatus.create(:name => "Done"),
    ]

    html = %{
      <tr><th data-column-id="#{status_1.id}">ToDo (<span class="count">0</span>)</th><th data-column-id="#{status_2.id}">Doing (<span class="count">0</span>)</th><th data-column-id="#{status_3.id}">Done (<span class="count">0</span>)</th></tr>
    }.strip.gsub(/\r/, "")

    headers = render_board_headers(columns)

    assert_equal html, headers
  end

  def test_render_board_headers_rowspan
    # | One  | Two    | Three |
    # |      | Doing  | Done  |
    columns = [
      status_1 = IssueStatus.create(:name => "One"),
      status_2 = IssueStatus.create(:name => "Two:Doing"),
      status_3 = IssueStatus.create(:name => "Three:Done"),
    ]

    html = %{
       <tr><th data-column-id="#{status_1.id}" rowspan="2">One (<span class="count">0</span>)</th><th>Two</th><th>Three</th></tr><tr><th data-column-id="#{status_2.id}">Doing (<span class="count">0</span>)</th><th data-column-id="#{status_3.id}">Done (<span class="count">0</span>)</th></tr>
    }.strip.gsub(/\r/, "")

    headers = render_board_headers(columns)

    assert_equal html, headers
  end

  def test_render_board_headers_colspan
    # | One  |       Two      |
    # |      | Doing  | Done  |
    columns = [
      status_1 = IssueStatus.create(:name => "One"),
      status_2 = IssueStatus.create(:name => "Two:Doing"),
      status_3 = IssueStatus.create(:name => "Two:Done"),
    ]

    html = %{
       <tr><th data-column-id="#{status_1.id}" rowspan="2">One (<span class="count">0</span>)</th><th colspan="2">Two</th></tr><tr><th data-column-id="#{status_2.id}">Doing (<span class="count">0</span>)</th><th data-column-id="#{status_3.id}">Done (<span class="count">0</span>)</th></tr>
    }.strip.gsub(/\r/, "")

    headers = render_board_headers(columns)

    assert_equal html, headers
  end

  def test_render_board_headers_colspan_first
    # |      One      | Two  |
    # | ToDo  | Doing | Done |
    columns = [
      status_1 = IssueStatus.create(:name => "One:ToDo"),
      status_2 = IssueStatus.create(:name => "One:Doing"),
      status_3 = IssueStatus.create(:name => "Two:Done"),
    ]

    html = %{
       <tr><th colspan="2">One</th><th>Two</th></tr><tr><th data-column-id="#{status_1.id}">ToDo (<span class="count">0</span>)</th><th data-column-id="#{status_2.id}">Doing (<span class="count">0</span>)</th><th data-column-id="#{status_3.id}">Done (<span class="count">0</span>)</th></tr>
    }.strip.gsub(/\r/, "")

    headers = render_board_headers(columns)

    assert_equal html, headers
  end

  def test_render_board_headers_three_levels
    # |         Mega One     |            |
    # |      One      | Two  |  Mega Two  |
    # | ToDo  | Doing | Done |            |
    columns = [
      status_1 = IssueStatus.create(:name => "Mega One:One:ToDo"),
      status_2 = IssueStatus.create(:name => "Mega One:One:Doing"),
      status_3 = IssueStatus.create(:name => "Mega One:Two:Done"),
      status_4 = IssueStatus.create(:name => "Mega Two"),
    ]

    html = %{
       <tr><th colspan="3">Mega One</th><th data-column-id="#{status_4.id}" rowspan="3">Mega Two (<span class="count">0</span>)</th></tr><tr><th colspan="2">One</th><th>Two</th></tr><tr><th data-column-id="#{status_1.id}">ToDo (<span class="count">0</span>)</th><th data-column-id="#{status_2.id}">Doing (<span class="count">0</span>)</th><th data-column-id="#{status_3.id}">Done (<span class="count">0</span>)</th></tr>
    }.strip.gsub(/\r/, "")

    headers = render_board_headers(columns)

    assert_equal html, headers
  end

  def test_render_board_headers_same_name_levels
    # |         Mega One     |            | Mega Two |
    # |      One      | Two  |  Mega Two  |    One   |
    # | ToDo  | Doing | Done |            |          |
    columns = [
      status_1 = IssueStatus.create(:name => "Mega One:One:ToDo"),
      status_2 = IssueStatus.create(:name => "Mega One:One:Doing"),
      status_3 = IssueStatus.create(:name => "Mega One:Two:Done"),
      status_4 = IssueStatus.create(:name => "Mega Two"),
      status_5 = IssueStatus.create(:name => "Mega Two:One"),
    ]

    html = %{
       <tr><th colspan="3">Mega One</th><th data-column-id="#{status_4.id}" rowspan="3">Mega Two (<span class="count">0</span>)</th><th>Mega Two</th></tr><tr><th colspan="2">One</th><th>Two</th><th data-column-id="#{status_5.id}" rowspan="2">One (<span class="count">0</span>)</th></tr><tr><th data-column-id="#{status_1.id}">ToDo (<span class="count">0</span>)</th><th data-column-id="#{status_2.id}">Doing (<span class="count">0</span>)</th><th data-column-id="#{status_3.id}">Done (<span class="count">0</span>)</th></tr>
    }.strip.gsub(/\r/, "")

    headers = render_board_headers(columns)

    assert_equal html, headers
  end

  def test_render_board_headers_keep_order
    # | Dev   |  Testing     | Dev  |
    # | ToDo  |              | Done |
    columns = [
      status_1 = IssueStatus.create(:name => "Dev:ToDo"),
      status_2 = IssueStatus.create(:name => "Testing"),
      status_3 = IssueStatus.create(:name => "Dev:Done")
    ]

    html = %{
       <tr><th>Dev</th><th data-column-id="#{status_2.id}" rowspan="2">Testing (<span class="count">0</span>)</th><th>Dev</th></tr><tr><th data-column-id="#{status_1.id}">ToDo (<span class="count">0</span>)</th><th data-column-id="#{status_3.id}">Done (<span class="count">0</span>)</th></tr>
    }.strip.gsub(/\r/, "")

    headers = render_board_headers(columns)

    assert_equal html, headers
  end

end
