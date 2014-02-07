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

require_dependency 'query'

module RedmineContacts
  module Patches
    module QueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, ContactsHelper)

        base.class_eval do
          unloadable
        end
      end


      module InstanceMethods
      end
    end
  end
end

unless Query.included_modules.include?(RedmineContacts::Patches::QueryPatch)
  Query.send(:include, RedmineContacts::Patches::QueryPatch)
end
