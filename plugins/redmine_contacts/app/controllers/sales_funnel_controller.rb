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

class SalesFunnelController < ApplicationController
  unloadable

  before_filter :find_optional_project

  helper :timelog
  helper :contacts
  helper :deals
  include ContactsHelper
  include DealsHelper

  def index
    @sales_funnel = []
    retrieve_date_range(params[:period])

    @sales_funnel_total = DealProcess.status_funnel_data(nil,
                        {:project_id => @project,
                         :from => @from, :to => @to,
                         :assigned_to_id => params[:assigned_to_id],
                         :author_id => params[:author_id],
                         :category_id => params[:category_id]}
                      )

    deal_statuses.each do |status|
      @sales_funnel << [status, DealProcess.status_funnel_data(status,
                        {:project_id => @project,
                         :from => @from, :to => @to,
                         :assigned_to_id => params[:assigned_to_id],
                         :author_id => params[:author_id],
                         :category_id => params[:category_id]}
                      )]
    end

    respond_to do |format|
      format.html{ render( :partial => "sales_funnel", :layout => false) if request.xhr? }
      format.xml { render :xml => @sales_funnel}
      format.json { render :text => @sales_funnel.to_json, :layout => false }
    end


  end
end
