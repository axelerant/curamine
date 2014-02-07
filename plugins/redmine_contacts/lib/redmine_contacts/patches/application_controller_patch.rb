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

module RedmineContacts
  module Patches
    module ApplicationControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :user_setup, :contacts
          helper :contacts, :deals, :notes
        end
      end

      module InstanceMethods
        def user_setup_with_contacts
          user_setup_without_contacts
          ContactsSetting.check_cache
        end

      end
    end
  end
end

unless ApplicationController.included_modules.include?(RedmineContacts::Patches::ApplicationControllerPatch)
  ApplicationController.send(:include, RedmineContacts::Patches::ApplicationControllerPatch)
end
