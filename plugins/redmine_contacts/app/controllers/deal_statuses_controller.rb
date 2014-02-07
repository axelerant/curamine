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

class DealStatusesController < ApplicationController
  unloadable

  layout 'admin'

  before_filter :require_admin, :except => :assing_to_project
  before_filter :find_project_by_project_id, :authorize, :only => :assing_to_project

  def index
    @deal_status_pages, @deal_statuses = paginate :deal_statuses, :per_page => 25, :order => "position"
    render :action => "index", :layout => false if request.xhr?
  end

  def new
    @deal_status = DealStatus.new
  end

  def create
    @deal_status = DealStatus.new(params[:deal_status])
    if @deal_status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action =>"plugin", :id => "redmine_contacts", :controller => "settings", :tab => 'deal_statuses'
    else
      render :action => 'new'
    end
  end

  def edit
    @deal_status = DealStatus.find(params[:id])
  end

  def update
    @deal_status = DealStatus.find(params[:id])
    if @deal_status.update_attributes(params[:deal_status])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action =>"plugin", :id => "redmine_contacts", :controller => "settings", :tab => 'deal_statuses'
    else
      render :action => 'edit'
    end
  end

  def destroy
    DealStatus.find(params[:id]).destroy
    redirect_to :action =>"plugin", :id => "redmine_contacts", :controller => "settings", :tab => 'deal_statuses'
  rescue
    flash[:error] = l(:error_unable_delete_deal_status)
    redirect_to :action =>"plugin", :id => "redmine_contacts", :controller => "settings", :tab => 'deal_statuses'
  end

  def assing_to_project

    if request.put?
      @project.deal_statuses = !params[:deal_statuses].blank? ? DealStatus.find(params[:deal_statuses]) : []
      @project.save
      flash[:notice] = l(:notice_successful_update)
    end
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'deals', :id => @project
  end

end
