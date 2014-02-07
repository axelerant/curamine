module RedmineHelpdesk
  module Hooks
    class ViewIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_edit_notes_bottom, :partial => 'issues/send_response'
      render_on :view_issues_sidebar_planning_bottom, :partial => "issues/helpdesk_customer_profile", :locals => {:issue => @issue}  
      render_on :view_issues_show_details_bottom, :partial => 'issues/ticket_data'
	    render_on :view_issues_form_details_bottom, :partial => 'issues/ticket_data_form'
    end
  end
end
