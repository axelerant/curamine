# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

require_dependency 'issue'

module RedmineChecklists
  module Patches

    module IssuePatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development

          has_many :checklists, :class_name => "Checklist", :dependent => :destroy, :inverse_of => :issue,
                   :order => 'position'

          accepts_nested_attributes_for :checklists, :allow_destroy => true, :reject_if => proc { |attrs| attrs["subject"].blank? }

          safe_attributes 'checklists_attributes',
            :if => lambda {|issue, user| (user.allowed_to?(:done_checklists, issue.project) ||
                                          user.allowed_to?(:edit_checklists, issue.project))}

        end


      end

    end

  end
end


unless Issue.included_modules.include?(RedmineChecklists::Patches::IssuePatch)
  Issue.send(:include, RedmineChecklists::Patches::IssuePatch)
end
