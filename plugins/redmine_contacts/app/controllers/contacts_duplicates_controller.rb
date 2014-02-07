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

class ContactsDuplicatesController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize, :except => :search
  before_filter :find_contact, :except => :duplicates
  before_filter :find_duplicate, :only => :merge

  helper :contacts

  def index
    @contacts = @contact.duplicates
  end

  def duplicates
    search_first_name = params[:contact][:first_name] if params[:contact] && !params[:contact][:first_name].blank?
    search_last_name = params[:contact][:last_name] if params[:contact] && !params[:contact][:last_name].blank?
    search_middle_name = params[:contact][:middle_name] if params[:contact] && !params[:contact][:middle_name].blank?

    @contact = (Contact.find(params[:contact_id]) if !params[:contact_id].blank?) || Contact.new
    @contact.first_name = search_first_name || ""
    @contact.last_name = search_last_name || ""
    @contact.middle_name = search_middle_name || ""
    respond_to do |format|
      format.html {render :partial => "duplicates", :layout => false if request.xhr?}
    end
  end

  def merge
    @duplicate.notes << @contact.notes
    @duplicate.deals << @contact.deals
    @duplicate.issues << @contact.issues
    @duplicate.projects << @contact.projects
    @duplicate.email = (@duplicate.emails | @contact.emails).join(', ')
    @duplicate.phone = (@duplicate.phones | @contact.phones).join(', ')

    call_hook(:controller_contacts_duplicates_merge, {:params => params, :duplicate => @duplicate, :contact => @contact})

    @duplicate.tag_list = @duplicate.tag_list | @contact.tag_list
    if @duplicate.save && @contact.destroy
      flash[:notice] = l(:notice_successful_merged)
      redirect_to :controller => "contacts", :action => "show", :project_id => @project, :id => @duplicate
    else
      render "index"
    end

  end

  def search
    @contacts = []
    q = (params[:q] || params[:term]).to_s.strip
    if q.present?
      scope = Contact.scoped({})
      scope = scope.limit(params[:limit] || 10)
      scope = scope.companies if params[:is_company]
      scope = scope.where(["#{Contact.table_name}.id <> ?", params[:contact_id].to_i]) if params[:contact_id]
      @contacts = scope.visible.by_project(@project).live_search(q).sort!{|x, y| x.name <=> y.name }
    else
      @contacts = @contact.duplicates
    end
    render :layout => false, :partial => 'list'
  end

  private

  def find_duplicate
    @duplicate = Contact.find(params[:duplicate_id])
    render_403 unless @duplicate.editable?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_contact
    @contact = Contact.find(params[:contact_id])
  rescue ActiveRecord::RecordNotFound
    render_404 if !request.xhr?
  end
end
