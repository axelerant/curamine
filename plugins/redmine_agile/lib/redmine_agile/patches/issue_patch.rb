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

require_dependency 'issue'
require_dependency 'agile_rank'

module RedmineAgile
  module Patches

    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          has_one :agile_rank, :dependent => :destroy

          scope :sorted_by_rank, lambda {includes(:agile_rank).
                                   order("COALESCE(#{AgileRank.table_name}.position, 999999)")}
          alias_method_chain :css_classes, :agile
          acts_as_colored

          safe_attributes 'agile_color_attributes',
            :if => lambda {|issue, user| user.allowed_to?(:edit_issues, issue.project) && user.allowed_to?(:view_agile_queries, issue.project) && RedmineAgile.issue_colors?}
          alias_method_chain :agile_rank, :default
        end
      end

      module InstanceMethods
        def agile_rank_with_default
          agile_rank_without_default || build_agile_rank
        end
        def css_classes_with_agile(user=User.current)
          s = if Redmine::VERSION.to_s < "2.4"
            css_classes_without_agile
          else
            css_classes_without_agile(user)
          end
          s << " #{RedmineAgile.color_prefix}-#{self.color}" if self.color && RedmineAgile.issue_colors?
          s
        end
      end
    end

  end
end

unless Issue.included_modules.include?(RedmineAgile::Patches::IssuePatch)
  Issue.send(:include, RedmineAgile::Patches::IssuePatch)
end
