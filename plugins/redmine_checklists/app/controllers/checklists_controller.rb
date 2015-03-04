# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

class ChecklistsController < ApplicationController
  unloadable

  before_filter :find_checklist_item, :except => [:index, :create]
  before_filter :find_issue_by_id, :only => [:index, :create]
  before_filter :authorize, :except => [:done]
  helper :issues

  accept_api_auth :index, :update, :destroy, :create, :show

  def index
    @checklists = @issue.checklists
    respond_to do |format|
      format.api
    end
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def destroy
    @checklist_item.destroy
    respond_to do |format|
      format.api {render_api_ok}
    end
  end

  def create
    @checklist_item = Checklist.new(params[:checklist])
    @checklist_item.issue = @issue
    respond_to do |format|
      format.api {
        if @checklist_item.save
          render :action => 'show', :status => :created, :location => checklist_url(@checklist_item)
        else
          render_validation_errors(@checklist_item)
        end
      }
    end
  end

  def update
    respond_to do |format|
      format.api {
        if @checklist_item.update_attributes(params[:checklist])
          render_api_ok
        else
          render_validation_errors(@checklist_item)
        end
      }
    end
  end

  def done
    (render_403; return false) unless User.current.allowed_to?(:done_checklists, @checklist_item.issue.project)

    old_checklist_item = @checklist_item.dup
    @checklist_item.is_done = !@checklist_item.is_done

    if @checklist_item.save
      if RedmineChecklists.settings[:save_log] && old_checklist_item.info != @checklist_item.info
        journal = Journal.new(:journalized => @checklist_item.issue, :user => User.current)
        journal.details << JournalDetail.new(:property => 'attr',
                                              :prop_key => 'checklist',
                                              :old_value => old_checklist_item.info,
                                              :value => @checklist_item.info)
        journal.save
      end

      if (Setting.issue_done_ratio == "issue_field") && RedmineChecklists.settings[:issue_done_ratio]
        done_checklist = @checklist_item.issue.checklists.map{|c| c.is_done ? 1 : 0}
        @checklist_item.issue.done_ratio = (done_checklist.count(1) * 10) / done_checklist.count * 10
        @checklist_item.issue.save
      end
    end
    respond_to do |format|
      format.js
      format.html {redirect_to :back }
    end
  end

  private

  def find_issue_by_id
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_checklist_item
    @checklist_item = Checklist.find(params[:id])
    @project = @checklist_item.issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end



end
