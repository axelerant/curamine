module RedmineHelpdesk
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do    
          unloadable # Send unloadable so it will not be unloaded in development
          has_one :customer, :through => :helpdesk_ticket
          has_one :helpdesk_ticket, :dependent => :delete

          scope :order_by_status, joins(:status).order("#{IssueStatus.table_name}.is_closed, #{IssueStatus.table_name}.id, #{Issue.table_name}.id DESC")

          accepts_nested_attributes_for :helpdesk_ticket

          safe_attributes 'helpdesk_ticket_attributes',
            :if => lambda {|issue, user| user.allowed_to?(:edit_helpdesk_tickets, issue.project)}

        end          
      end


      module InstanceMethods
        def last_message
          self.helpdesk_ticket.last_message.content.truncate(250) if self.helpdesk_ticket
        end

        def ticket_source
          self.helpdesk_ticket.ticket_source_name if self.helpdesk_ticket
        end

        def customer_company
          return nil unless self.customer
          self.customer.company
        end        

        def last_message_date
          self.helpdesk_ticket.last_message_date if self.helpdesk_ticket
        end  

      end

    end
  end
end

unless Issue.included_modules.include?(RedmineHelpdesk::Patches::IssuePatch)
  Issue.send(:include, RedmineHelpdesk::Patches::IssuePatch)
end
