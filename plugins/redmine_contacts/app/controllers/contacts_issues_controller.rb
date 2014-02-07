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

class ContactsIssuesController < ApplicationController
  unloadable

  before_filter :find_contact, :only => [:create_issue, :delete]
  before_filter :find_issue, :except => [:create_issue]
  before_filter :find_project_by_project_id, :only => [:create_issue]
  before_filter :authorize_global, :only => [:close]
  before_filter :authorize

  helper :contacts

  def create_issue
    deny_access unless @contact.editable? || User.current.allowed_to?(:add_issues, @project)
    issue = Issue.new
    issue.project = @project
    issue.author = User.current
    issue.status = IssueStatus.default
    issue.start_date ||= Date.today
    issue.contacts << @contact
    issue.safe_attributes = params[:issue] if params[:issue]

    if issue.save
      flash[:notice] = l(:notice_successful_add)
      redirect_to :back
    else
      redirect_to :back
    end
  end

  def create
    contact_ids = []
    if params[:contacts_issue].is_a?(Hash)
      contact_ids << (params[:contacts_issue][:contact_ids] || params[:contacts_issue][:contact_id])
    else
      contact_ids << params[:contact_id]
    end
    contact_ids.flatten.compact.uniq.each do |contact_id|
      ContactsIssue.create(:issue_id => @issue.id, :contact_id => contact_id)
    end
    respond_to do |format|
      format.html { redirect_to_referer_or {render :text => 'Added.', :layout => true}}
      format.js
    end
  end

  def new
  end

  def delete
    @issue.contacts.delete(@contact)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  def close
    @issue.status = IssueStatus.find(:first, :conditions =>  { :is_closed => true })
    @issue.save
    respond_to do |format|
      format.js
      format.html {redirect_to :back }
    end

  end

  def autocomplete_for_contact
    @contacts = Contact.visible.includes(:avatar).order_by_name.live_search(params[:q]).by_project(params[:cross_project_contacts] == "1" ? nil : @project).limit(100)
    if @issue
      @contacts -= @issue.contacts
    end
    render :layout => false
  end

  private

  def find_contact
    @contact = Contact.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end


end
