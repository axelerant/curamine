# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2013   Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module RedmineDmsf
  module Hooks
    class ViewProjectsFormHook < Redmine::Hook::ViewListener
      include Redmine::I18n

      def view_projects_form(context={})
        context[:controller].send(:render_to_string, {
          :partial => 'hooks/redmine_dmsf/view_projects_form',
          :locals => context
        })

      end

    end
  end
end
