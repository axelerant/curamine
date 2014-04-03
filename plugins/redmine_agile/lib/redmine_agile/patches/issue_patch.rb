# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2014 RedmineCRM
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
require_dependency 'issue_status_order'

module RedmineAgile
  module Patches

    module IssuePatch
      def self.included(base)
        base.class_eval do
          unloadable
          has_one :issue_status_order, :dependent => :destroy
          scope :sorted_by_status, includes(:issue_status_order).
                                   order("#{IssueStatusOrder.table_name}.position IS NULL, #{IssueStatusOrder.table_name}.position")

          def issue_status_order_with_default
            issue_status_order_without_default || build_issue_status_order
          end
          alias_method_chain :issue_status_order, :default

        end
      end
    end

  end
end

unless Issue.included_modules.include?(RedmineAgile::Patches::IssuePatch)
  Issue.send(:include, RedmineAgile::Patches::IssuePatch)
end
