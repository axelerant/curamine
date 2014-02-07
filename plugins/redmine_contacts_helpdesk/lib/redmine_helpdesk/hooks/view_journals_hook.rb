include ContactsHelper           

module RedmineHelpdesk
  module Hooks
    class ShowJournalContactHook < Redmine::Hook::ViewListener     
      render_on :view_issues_history_journal_bottom, :partial => "journals/journal_contact" 
    end   
  end
end