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
    module SettingPatch
      def self.included(base)
        base.extend(ClassMethods)
        # base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          # Setting.available_settings["disable_taxes"] = {'default' => 0}
          # @@available_settings["disable_taxes"] = {}

        end
      end

      module ClassMethods

        # Setting.available_settings["disable_taxes"] = {}

        # def disable_taxes?
        #   self[:disable_taxes].to_i > 0
        # end

        # def disable_taxes=(value)
        #   self[:disable_taxes] = value
        # end

        %w(disable_taxes default_tax tax_type default_currency money_thousands_delimiter money_decimal_separator).each do |name|
          src = <<-END_SRC
          Setting.available_settings["#{name}"] = ""

          def #{name}
            self[:#{name}]
          end

          def #{name}?
            self[:#{name}].to_i > 0
          end

          def #{name}=(value)
            self[:#{name}] = value
          end
          END_SRC
          class_eval src, __FILE__, __LINE__
        end

      end
    end
  end
end

unless Setting.included_modules.include?(RedmineContacts::Patches::SettingPatch)
  Setting.send(:include, RedmineContacts::Patches::SettingPatch)
end
