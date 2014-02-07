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

class ContactsSettingsController < ApplicationController
  unloadable
  before_filter :find_project_by_project_id, :authorize

  def save
    if params[:contacts_settings] && params[:contacts_settings].is_a?(Hash) then
      settings = params[:contacts_settings]
      settings.map do |k, v|
        ContactsSetting[k, @project.id] = v
      end
    end
    redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => params[:tab]
  end

end
