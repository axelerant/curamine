module RedmineHelpdesk
  module Hooks
    class ControllerContactsDuplicatesHook < Redmine::Hook::ViewListener
      def controller_contacts_duplicates_merge(context={})
        context[:duplicate].journal_messages << context[:contact].journal_messages
        context[:duplicate].helpdesk_tickets << context[:contact].helpdesk_tickets
      end
    end
  end
end      