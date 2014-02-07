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

class ContactsTagsController < ApplicationController
  unloadable
  before_filter :require_admin
  before_filter :find_tag, :only => [:edit, :update]
  before_filter :bulk_find_tags, :only => [:context_menu, :merge, :destroy]

  def index
  end

  def edit
  end

  def destroy
    @tags.each do |tag|
      begin
        tag.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if tag no longer exists
        # nothing to do, tag was already deleted (eg. by a parent)
      end
    end
    redirect_back_or_default(:controller => 'settings', :action => 'plugin', :id => 'redmine_contacts', :tab => "tags")
  end

  def update
    @tag.name = params[:tag][:name]
    if @tag.save

      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to :controller => 'settings', :action => 'plugin', :id => 'redmine_contacts', :tab => "tags" }
        format.xml  { }
      end
    else
      respond_to do |format|
        format.html { render :action => "edit"}
      end
    end
  end

  def context_menu
    @tag = @tags.first if (@tags.size == 1)
    @back = back_url
    render :layout => false
  end

  def merge
    if request.post? && params[:tag] && params[:tag][:name]
      ActsAsTaggableOn::Tagging.transaction do
        tag = ActsAsTaggableOn::Tag.find_by_name(params[:tag][:name]) || ActsAsTaggableOn::Tag.create(params[:tag])
        ActsAsTaggableOn::Tagging.where(:tag_id => @tags.map(&:id)).update_all(:tag_id => tag.id)
        @tags.select{|t| t.id != tag.id}.each{|t| t.destroy }
        redirect_to :controller => 'settings', :action => 'plugin', :id => 'redmine_contacts', :tab => "tags"
      end
    end
  end

  private

  def bulk_find_tags
    @tags = ActsAsTaggableOn::Tag.find_all_by_id(params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @tags.empty?
  end

  def find_tag
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
