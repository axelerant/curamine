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

class TasksController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize, :except => [:index]
  before_filter :find_optional_project, :only => :index
  before_filter :find_taskable, :except => [:index, :add, :close]
  before_filter :find_issue, :except => [:index, :new]

  def index
    cond = "(1=1)"
    # cond = "issues.assigned_to_id = #{User.current.id}"
    cond << " and issues.project_id = #{@project.id}" if @project
    cond << " and (issues.assigned_to_id = #{params[:assigned_to]})" unless params[:assigned_to].blank?

    @tasks = Issue.visible.find(:all,
                                :joins => "INNER JOIN tasks ON issues.id = tasks.issue_id",
                                # :group => :issue_id,
                                :conditions => cond,
                                :order => "issues.due_date")
    @users = assigned_to_users
  end

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
      @taskable.issues << issue
      @taskable.save
      redirect_to :back
      return
    else
      redirect_to :back
    end
  end

  def add
    @show_form = "true"

    if params[:source_id] && params[:source_type] && request.post? then
      find_taskable
      @taskable.issues << @issue
      @taskable.save
    end

    taskable_name = @taskable.class.name.underscore

    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html "issue_#{taskable_name}s", :partial => "issues/#{taskable_name}s"
        end
      end
    end
  end

  def delete
    @issue.taskables.delete(@taskable)
    taskable_name =  @taskable.class.name.underscore
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html "issue_#{taskable_name}s", :partial => "issues/#{taskable_name}s"
        end
      end
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

  def find_taskable
    klass = Object.const_get(params[:source_type].camelcase)
    @taskable = klass.find(params[:source_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue
    @issue = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def assigned_to_users
    user_values = []
    project = @project
    user_values << ["<< #{l(:label_all)} >>", ""]
    user_values << ["<< #{l(:label_me)} >>", User.current.id] if User.current.logged?
    if project
      user_values += project.users.sort.collect{|s| [s.name, s.id.to_s] }
    else
      project_ids = Project.all(:conditions => Project.visible_condition(User.current)).collect(&:id)
      if project_ids.any?
        # members of the user's projects
        user_values += User.active.find(:all, :conditions => ["#{User.table_name}.id IN (SELECT DISTINCT user_id FROM members WHERE project_id IN (?))", project_ids]).sort.collect{|s| [s.name, s.id.to_s] }
      end
    end
  end


end
