# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
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

module RedmineChecklists
  module Hooks
    class ControllerIssueHook < Redmine::Hook::ViewListener

      def controller_issues_edit_before_save(context={})
        return false unless RedmineChecklists.settings[:save_log]
        old_checklist = Issue.find(context[:issue].id).checklists.collect(&:info).join(', ')
        save_journal_to_issue(context, true, old_checklist)
      end

      def controller_issues_new_before_save(context={})
        return false unless RedmineChecklists.settings[:save_log]
        old_checklist = 'none'
        save_journal_to_issue(context, false, old_checklist)
      end

      def save_journal_to_issue(context, create_journal, old_checklist={})
        checklist = context[:issue].try(:checklists)
        new_checklist = checklist.collect(&:info).join(', ') if checklist
        if checklist && checklist.any? && create_journal && !((new_checklist == old_checklist) || context[:issue].current_journal.blank?)
          context[:issue].current_journal.details << JournalDetail.new(:property => 'attr',
                                                                       :prop_key => 'checklist',
                                                                       :old_value => old_checklist,
                                                                       :value => new_checklist)
        end
      end

    end
  end
end
