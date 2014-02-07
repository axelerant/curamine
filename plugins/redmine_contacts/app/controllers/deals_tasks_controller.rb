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

class DealsTasksController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize
  before_filter :find_deal, :except => [:close]
  before_filter :find_issue, :except => [:new]

  def new
    issue = Issue.new
    issue.subject = params[:task_subject]
    issue.project = @project
    issue.tracker_id = params[:task_tracker]
    issue.author = User.current
    issue.due_date = params[:due_date]
    issue.assigned_to_id = params[:assigned_to]
    issue.description = params[:task_description]
    issue.status = IssueStatus.default
    if issue.save
      flash[:notice] = l(:notice_successful_add)
      @deal.issues << issue
      @deal.save
      redirect_to :back
      return
    else
      redirect_to :back
    end
  end


  def close
    @issue.status = IssueStatus.find(:first, :conditions =>  { :is_closed => true })
    @issue.save
    respond_to do |format|
      format.js do
        render :update do |page|
            page["issue_#{params[:issue_id]}"].visual_effect :fade
        end
      end
      format.html {redirect_to :back }
    end

  end

  private

  def find_deal
    @deal = Deal.find(params[:deal_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue
    @issue = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end


end
