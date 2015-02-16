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

class AgileQueriesController < ApplicationController
  unloadable

  menu_item :agile

  before_filter :find_query, :except => [:new, :create, :index]
  before_filter :find_optional_project, :only => [:new, :create]

  include QueriesHelper
  helper :queries
  helper :agile_boards

  def index
    @limit = per_page_option
    @query_count = AgileQuery.visible.count
    @query_pages = Paginator.new @query_count, @limit, params['page']
    @queries = AgileQuery.visible.
                    order("#{Query.table_name}.name").
                    limit(@limit).
                    offset(@offset).
                    all
  end

  def new
    @query = AgileQuery.new
    @query.user = User.current
    @query.project = @project
    @query.visibility = AgileQuery::VISIBILITY_PRIVATE unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
    @query.build_from_params(params)
  end

  def create
    @query = AgileQuery.new(params[:query])
    @query.user = User.current
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.visibility = AgileQuery::VISIBILITY_PRIVATE unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
    @query.build_from_params(params)
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_agile_board(:query_id => @query)
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    @query.attributes = params[:query]
    @query.project = nil if params[:query_is_for_all]
    @query.visibility = AgileQuery::VISIBILITY_PRIVATE unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
    @query.build_from_params(params)
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_agile_board(:query_id => @query)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to_agile_board(:set_filter => 1)
  end

private
  def find_query
    @query = AgileQuery.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:add_agile_queries, @project, :global => true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def redirect_to_agile_board(options)
    if @project
      redirect_to agile_board_path(options.merge(:project_id => @project))
    else
      redirect_to agile_board_path(options)
    end
  end
end
