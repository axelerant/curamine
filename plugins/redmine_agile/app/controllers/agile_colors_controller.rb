# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2015 RedmineCRM
# http://www.redminecrm.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

class AgileColorsController < ApplicationController
  unloadable

  layout 'admin'

  before_filter :require_admin
  before_filter :find_coloreds, :only => [:index, :update]

  def index
  end

  def update
    @colored_class.transaction do
      params[:coloreds].each do |colored|
        @colored_class.update(colored[:id], :color => colored[:color])
      end
      flash[:notice] = l(:notice_successful_update)
    end
    redirect_to :action => :index, :object_type => params[:object_type]
  end

  private

  def find_coloreds
    klass = Object.const_get(params[:object_type].camelcase) rescue nil
    @colored_class = klass
    @coloreds = klass.sorted if klass && klass.new.respond_to?('color')
    render_404 unless @coloreds.present?
  end

end
