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

class AgileBoardController < ApplicationController
  unloadable

  menu_item :issues

  before_filter :find_issue, :only => [:update]
  before_filter :find_optional_project, :only => [:index]

  helper :issues
  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog

  def index
    retrieve_query

    if @query.valid?
      case params[:format]
      when 'pdf'
        @limit = Setting.issues_export_limit.to_i
        if params[:columns] == 'all'
          @query.column_names = @query.available_inline_columns.map(&:name)
        end
      else
        @limit = per_page_option
      end

      @issue_count = @query.issue_count
      status_filter_operator = @query.filters.fetch("status_id", {}).fetch(:operator, nil)
      status_filter_values = @query.filters.fetch("status_id", {}).fetch(:values, [])
      @board_statuses = IssueStatus.where(:id => Tracker.includes(:issues => [:status, :project]).where(@query.statement).map(&:issue_statuses).flatten.uniq.map(&:id))
      @board_statuses = case status_filter_operator
                        when "o"
                          @board_statuses.where(:is_closed => false).sorted
                        when "c"
                          @board_statuses.where(:is_closed => true).sorted
                        when "="
                          @board_statuses.where(:id => status_filter_values).sorted
                        when "!"
                          @board_statuses.where("#{IssueStatus.table_name}.id NOT IN (" + value.status_filter_values{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")").sorted
                        else
                          @board_statuses.sorted
                        end

      @issues = Issue.visible.
                  includes(:status,
                           :project,
                           :attachments,
                           :assigned_to,
                           :tracker,
                           :priority,
                           :category,
                           :fixed_version).
                  where(@query.statement)

      @board_columns = []
      @board_statuses.each do |status|
        total_issues = @issues.where(:status_id => status.id)
        limited_issues = total_issues.limit(RedmineAgile.issues_per_column).sorted_by_status
        @board_columns << {
          :status => status,
          :issues => limited_issues,
          :limited_count => limited_issues.count,
          :total_count => total_issues.count
        }
        # Issue.load_visible_spent_hours(@board_columns.last[:issues])
      end
      respond_to do |format|
        format.html { render :template => 'agile_board/index', :layout => !request.xhr? }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'agile_board/index', :layout => !request.xhr?) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update
    (render_403; return false) unless @issue.editable?
    @issue.init_journal(User.current)
    @issue.safe_attributes = params[:issue]
    if @issue.save
      if @issue.status_id != params[:issue][:status_id].to_i
        status = :fail
        response = [l(:error_redmine_agile_status_transition)]
      else
        status = :ok
        response = @issue
        IssueStatusOrder.transaction do
          Issue.includes(:issue_status_order).find(params[:positions].keys).each do |issue|
            issue.issue_status_order.position = params[:positions][issue.id.to_s]['position']
            issue.issue_status_order.save
          end
        end
      end
      respond_to do |format|
        format.html { render :json => response, :status => status, :layout => nil }
      end
    else
      respond_to do |format|
        format.html { render :json => @issue.errors.full_messages, :status => :fail, :layout => nil }
      end
    end
  end

  def load_more
    @issues = Issue.visible.
                includes(:status,
                         :project,
                         :attachments,
                         :assigned_to,
                         :tracker,
                         :priority,
                         :category,
                         :fixed_version).
                where(:status_id => params[:status_id]).limit(Setting.plugin_redmine_agile['issues_per_column']).offset(params[:offset])
    respond_to do |format|
      format.js
    end
  end

end
