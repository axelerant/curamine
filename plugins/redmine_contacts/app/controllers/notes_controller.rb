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

class NotesController < ApplicationController
  unloadable
  default_search_scope :notes
  # before_filter :find_model_object
  before_filter :find_note, :only => [:show, :edit, :update, :destroy]
  before_filter :find_project, :only => :create
  before_filter :find_note_source, :only => :create
  before_filter :find_optional_project, :only => :show

  accept_api_auth :show, :create, :update, :destroy

  helper :attachments
  helper :notes
  helper :contacts
  helper :custom_fields

  def show
    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    find_note_source
    @note = Note.new
    @note.source = @note_source
  end

  def edit
    (render_403; return false) unless @note.editable_by?(User.current, @project)
  end

  def update
    if @note.update_attributes(params[:note])
      @note.note_time = params[:note][:note_time] if params[:note] && params[:note][:note_time]
      attachments = Attachment.attach_files(@note, (params[:attachments] || (params[:note] && params[:note][:uploads])))
      render_attachment_warning_if_needed(@note)
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_back_or_default({:action => "show", :project_id => @note.source.project, :id => @note}) }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit', :project_id => params[:project_id], :id => @note }
        format.api  { render_validation_errors(@note) }
      end
    end
  end

  def create
    @note = Note.new(params[:note])
    @note.source = @note_source
    @note.note_time = params[:note][:note_time] if params[:note] && params[:note][:note_time]
    @note.author = User.current
    if @note.save
      attachments = Attachment.attach_files(@note, (params[:attachments] || (params[:note] && params[:note][:uploads])))
      render_attachment_warning_if_needed(@note)

      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.js
        format.html {redirect_to :back}
        format.api  { render :action => 'show', :status => :created, :location => note_url(@note) }
      end
    else
      respond_to do |format|
        format.html { redirect_to :back }
        format.api  { render_validation_errors(@note) }
      end
    end
  end

  def destroy
    (render_403; return false) unless @note.destroyable_by?(User.current, @project)
    @note.destroy
    respond_to do |format|
      format.js
      format.html {redirect_to :action => 'show', :project_id => @project, :id => @note.source }
      format.api  { render_api_ok }
    end

    # redirect_to :action => 'show', :project_id => @project, :id => @contact
  end


  private

  def find_project
    project_id = (params[:note] && params[:note][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_note
    @note = Note.find(params[:id])
    @project ||= @note.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_note_source
    note_source_type = (params[:note] && params[:note][:source_type]) || params[:source_type]
    note_source_id = (params[:note] && params[:note][:source_id]) || params[:source_id]

    klass = Object.const_get(note_source_type.camelcase)
    @note_source = klass.find(note_source_id)
  end

end
