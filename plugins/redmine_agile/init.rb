# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2014 RedmineCRM
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

require 'redmine_agile'

AGILE_VERSION_NUMBER = '1.0.1'

Redmine::Plugin.register :redmine_agile do
  name 'Redmine Agile plugin'
  author 'RedmineCRM'
  description 'Scrum and Agile project management plugin for redmine'
  version AGILE_VERSION_NUMBER + '-light' + AGILE_VERSION_NUMBER
  url 'http://redminecrm.com'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.3'

  settings :default => { 'issues_per_column' => RedmineAgile::ISSUES_PER_COLUMN },
           :partial => 'settings/agile_board/agile_board'

  Redmine::AccessControl.map do |map|
    map.project_module :issue_tracking do |map|
      map.permission :view_agile_board, {:agile_board => :index}
    end
  end
end

require_dependency 'redmine_agile/patches/issue_patch'
