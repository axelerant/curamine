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

class DealCategoriesController < ApplicationController
  unloadable
  menu_item :settings
  model_object DealCategory
  before_filter :find_model_object, :except => :new
  before_filter :find_project_from_association, :except => :new
  before_filter :find_project_by_project_id, :only => :new
  before_filter :authorize

  def new
    @category = @project.deal_categories.build(params[:category])
    if request.post?
      if @category.save
        respond_to do |format|
          format.html do
            flash[:notice] = l(:notice_successful_create)
            redirect_to :controller => 'projects', :action => 'settings', :tab => 'deals', :id => @project
          end
          format.js do
            # IE doesn't support the replace_html rjs method for select box options
            render(:update) {|page| page.replace "deal_category_id",
              content_tag('select', '<option></option>' + options_from_collection_for_select(@project.deal_categories, 'id', 'name', @category.id), :id => 'deal_category_id', :name => 'deal[category_id]')
            }
          end
        end
      else
        respond_to do |format|
          format.html
          format.js do
            render(:update) {|page| page.alert(@category.errors.full_messages.join('\n')) }
          end
        end
      end
    end
  end

  def edit
    if request.put? and @category.update_attributes(params[:category])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :controller => 'projects', :action => 'settings', :tab => 'deals', :id => @project
    end
  end

  def destroy
    debugger
    @deal_count = @category.deals.size
    if @deal_count == 0
      # No deal assigned to this category
      @category.destroy
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'deals'
    elsif params[:todo]
      reassign_to = @project.deal_categories.find_by_id(params[:reassign_to_id]) if params[:todo] == 'reassign'
      @category.destroy(reassign_to)
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'deals'
    end
    @categories = @project.deal_categories - [@category]
  end

  private
  # Wrap ApplicationController's find_model_object method to set
  # @category instead of just @deal_category
  def find_model_object
    super
    @category = @object
    @project = @category.project
  end
end
