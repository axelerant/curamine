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
  module Hooks
    class ControllersTimeEntryReportsHook < Redmine::Hook::ViewListener
      def controller_timelog_available_criterias(context={})
        context[:available_criterias]["contacts"] = {:sql => "contacts_issues.contact_id",
                                         			 :klass => Contact,
                                         			 :label => :label_crm_contact}
      end

      def controller_timelog_time_report_joins(context={})
      	context[:sql] << " LEFT JOIN contacts_issues ON contacts_issues.issue_id = #{Issue.table_name}.id"
      end
    end
  end
end
