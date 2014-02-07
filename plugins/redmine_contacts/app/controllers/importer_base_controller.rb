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

class ImporterBaseController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize

  def new
    @importer = klass.new
    render 'importers/new'
  end

  def create
    @importer = klass.new(params[klass.to_s.underscore.to_sym])
    @importer.project = @project
    if @importer.file && @importer.save
      redirect_to instance_index
    else
      render 'importers/new'
    end
  end
end
