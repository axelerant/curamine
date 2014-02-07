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

require_dependency 'queries_helper'

module RedmineContacts
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :column_value, :contacts
        end
      end


      module InstanceMethods
        def column_value_with_contacts(column, issue, value)
          case value.class.name
          when 'Contact'
            contact_tag(value)
          else
            column_value_without_contacts(column, issue, value)
          end
        end

      end

    end
  end
end

unless QueriesHelper.included_modules.include?(RedmineContacts::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedmineContacts::Patches::QueriesHelperPatch)
end
