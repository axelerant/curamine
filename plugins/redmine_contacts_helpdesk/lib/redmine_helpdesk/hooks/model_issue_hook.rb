module RedmineHelpdesk
  module Hooks
    class ModelIssueHook < Redmine::Hook::ViewListener
      # def controller_issues_new_after_save(context={})
      def controller_issues_new_before_save(context={})
        if context[:params] && context[:params][:helpdesk_ticket] && !context[:params][:helpdesk_ticket][:contact_id].blank? && User.current.allowed_to?(:edit_helpdesk_tickets, context[:issue].project)
          params = context[:params]
          helpdesk_ticket = HelpdeskTicket.new(params[:helpdesk_ticket])
          helpdesk_ticket.issue = context[:issue]
          helpdesk_ticket.customer.project = context[:issue].project if helpdesk_ticket.customer && helpdesk_ticket.customer.project.blank?
          helpdesk_ticket.from_address = helpdesk_ticket.customer.primary_email if helpdesk_ticket.customer
          context[:issue].helpdesk_ticket = helpdesk_ticket
          # helpdesk_ticket.save
        end
      end
    end
  end
end
