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

class ContactsProjectsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize
  before_filter :find_contact
  before_filter :check_count, :find_related_project, :only => :delete

  helper :contacts

  def add
    @show_form = "true"
    # find_contact
    if params[:related_project_id] then
      find_related_project
      @contact.projects << @related_project
      @contact.save if request.post?
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  rescue ::ActionController::RedirectBackError
    render :text => 'Project added.', :layout => true
  end

  def delete
    @contact.projects.delete(@related_project) if request.delete?
    respond_to do |format|
      format.html { redirect_to :back }
      format.js {render :action => "add"}
    end
  end

  private

  def find_related_project
    @related_project = Project.find(params[:related_project_id])
    raise Unauthorized unless User.current.allowed_to?(:edit_contacts, @related_project)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_count
    deny_access if @contact.projects.size <= 1
  end

  def find_contact
    @contact = Contact.find(params[:contact_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
