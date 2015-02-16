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

module AgileVersionsHelper
  def version_select_tag(version, option={})
    return "" if version.blank?
    version_id =  version.is_a?(Version) && version.id || version
    other_version_id = option[:other_version].is_a?(Version) && option[:other_version].id || option[:other_version]
    select_tag('version_id',
      options_for_select(versions_collection_for_select,
          {:selected => version_id, :disabled => other_version_id}),
      :data => {:remote => true,
                :method => 'get',
                :url => load_agile_versions_path(:version_type => option[:version_type],
                                                 :other_version_id => other_version_id,
                                                 :project_id => @project)})
  end

  def versions_collection_for_select
    @project.shared_versions.open.map{|version| [format_version_name(version), version.id.to_s]}
  end
end
