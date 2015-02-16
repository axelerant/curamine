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

module RedmineAgile
  module Acts
    module Colored
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_colored(options = {})
          return if self.included_modules.include?(RedmineAgile::Acts::Colored::InstanceMethods)
          send :include, RedmineAgile::Acts::Colored::InstanceMethods

          class_eval do
            has_one :agile_color, :as => :container, :dependent => :destroy
            delegate :color, :to => :agile_color, :allow_nil => true

            accepts_nested_attributes_for :agile_color, :reject_if => :reject_color, :allow_destroy => true

            alias_method_chain :agile_color, :default
          end

        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        def reject_color(attributes)
          exists = attributes['id'].present?
          empty = attributes[:color].blank?
          attributes.merge!({:_destroy => 1}) if exists and empty
          return (!exists and empty)
        end

        def color=(value)
          self.agile_color.color = value
        end

        def agile_color_with_default
          agile_color_without_default || build_agile_color
        end

        module ClassMethods
        end
      end
    end
  end
end
