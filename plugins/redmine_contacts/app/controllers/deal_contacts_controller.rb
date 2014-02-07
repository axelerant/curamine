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

class DealContactsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize
  before_filter :find_contact, :only => :delete
  before_filter :find_deal

	helper :deals
  helper :contacts

  def add
    @show_form = "true"

    if params[:contact_id] && request.post? then
      find_contact
      if !@deal.all_contacts.include?(@contact)
        @deal.related_contacts << @contact
        @deal.save
      end
    end

    respond_to do |format|
      format.html do
        redirect_to :back
      end
      format.js
    end
  end

  def delete
    @deal.related_contacts.delete(@contact)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end


	private
  def find_contact
    @contact = Contact.find(params[:contact_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_deal
    @deal = Deal.find(params[:deal_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
