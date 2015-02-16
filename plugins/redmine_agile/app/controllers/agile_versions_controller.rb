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

class AgileVersionsController < ApplicationController
  unloadable

  menu_item :agile

  before_filter :find_project_by_project_id, :only => [:index, :autocomplete, :load]
  before_filter :find_version, :only => [:load]
  before_filter :authorize, :except => [:autocomplete, :load]
  before_filter :find_no_version_issues, :only => [:index, :autocomplete]

  def index
    @backlog_version = @project.shared_versions.open.where("LOWER(#{Version.table_name}.name) LIKE LOWER(?)", "backlog").first ||
        @project.shared_versions.open.where(:effective_date => nil).first ||
        @project.shared_versions.open.order("effective_date ASC").first
    @current_version = Version.open.
        where(:project_id => @project).
        where("#{Version.table_name}.id <> ?", @backlog_version).
        order("effective_date DESC").first
  end

  def autocomplete
    render :layout => false
  end

  def load
    @version_issues = @version.fixed_issues.open.visible.sorted_by_rank
    @version_type = params[:version_type]
    @other_version_type = @version_type == "backlog" ? "current" : "backlog"
    @other_version_id = params[:other_version_id]
    respond_to do |format|
      format.js
    end
  end

  private

  def find_version
    @version = Version.visible.find(params[:version_id])
    @project ||= @version.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_no_version_issues
    q = (params[:q] || params[:term]).to_s.strip
    scope = Issue.open.visible
    if @project
      project_ids = [@project.id]
      project_ids += @project.descendants.collect(&:id) if Setting.display_subprojects_issues?
      scope = scope.where(:project_id => project_ids)
    end
    scope = scope.where(:fixed_version_id => nil).sorted_by_rank
    if q.present?
      if q.match(/^#?(\d+)\z/)
        scope = scope.where("(#{Issue.table_name}.id = ?) OR (LOWER(#{Issue.table_name}.subject) LIKE LOWER(?))", $1.to_i, "%#{q}%")
      else
        scope = scope.where("LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)", "%#{q}%")
      end
    end
    @issue_count = scope.count
    @issue_pages = Redmine::Pagination::Paginator.new @issue_count, 20, params['page']
    @version_issues = scope.offset(@issue_pages.offset).limit(@issue_pages.per_page).all
  end

end
