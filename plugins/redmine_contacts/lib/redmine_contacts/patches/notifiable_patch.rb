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
    module NotifiablePatch
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
            unloadable
            class << self
                alias_method_chain :all, :crm
            end
        end
      end


      module ClassMethods
        # include ContactsHelper

        def all_with_crm
          notifications = all_without_crm
          notifications << Redmine::Notifiable.new('crm_contact_added')
          notifications << Redmine::Notifiable.new('crm_deal_added')
          notifications << Redmine::Notifiable.new('crm_deal_updated')
          notifications << Redmine::Notifiable.new('crm_note_added')
          notifications
        end

      end

    end
  end
end

unless Redmine::Notifiable.included_modules.include?(RedmineContacts::Patches::NotifiablePatch)
  Redmine::Notifiable.send(:include, RedmineContacts::Patches::NotifiablePatch)
end
