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

class ContactsQueriesController < ApplicationController
  unloadable

  before_filter :find_query, :except => [:new, :create, :index]
  before_filter :find_optional_project, :only => [:new, :create]

  accept_api_auth :index

  helper :queries
  include QueriesHelper

  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    scope = ContactsQuery.scoped({})
    scope = scope.where(:type => params[:type]) if params[:type]
    @query_count = scope.visible.count
    @query_pages = Paginator.new self, @query_count, @limit, params['page']
    @queries = scope.visible.offset(@offset).order("#{ContactsQuery.table_name}.name").first(@limit)

    respond_to do |format|
      format.html { render :nothing => true }
      format.api
    end
  end

  def new
    @query = ContactsQuery.new
    @query.user = User.current
    @query.project = @project
    @query.is_public = false unless User.current.allowed_to?(:manage_public_contacts_queries, @project) || User.current.admin?
    @query.build_from_params(params)
  end

  def create
    @query = ContactsQuery.new(params[:query])
    @query.user = User.current
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.is_public = false unless User.current.allowed_to?(:manage_public_contacts_queries, @project) || User.current.admin?
    @query.build_from_params(params)
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :controller => 'contacts', :action => 'index', :project_id => @project, :query_id => @query
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    @query.attributes = params[:query]
    @query.project = nil if params[:query_is_for_all]
    @query.is_public = false unless User.current.allowed_to?(:manage_public_contacts_queries, @project) || User.current.admin?
    @query.build_from_params(params)
    @query.column_names = nil if params[:default_columns]

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :controller => 'contacts', :action => 'index', :project_id => @project, :query_id => @query
    else
      render :action => 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to :controller => 'contacts', :action => 'index', :project_id => @project, :set_filter => 1
  end

private
  def find_query
    @query = ContactsQuery.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:save_contacts_queries, @project, :global => true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
