module RedmineHelpdesk
  module Patches
    module ContactsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :contact_tabs, :helpdesk          
        end
      end


      module InstanceMethods
        # include ContactsHelper

        def contact_tabs_with_helpdesk(contact)
          tabs = contact_tabs_without_helpdesk(contact)

          if contact.all_tickets.visible.count > 0
            tabs.push({:name => 'helpdesk', :partial => 'contacts/helpdesk_tickets', :label => l(:label_helpdesk_ticket_plural) + " (#{contact.all_tickets.visible.open.count}/#{contact.all_tickets.visible.count})"} )
          end
          tabs
        end
        
      end
      
    end
  end
end

unless ContactsHelper.included_modules.include?(RedmineHelpdesk::Patches::ContactsHelperPatch)
  ContactsHelper.send(:include, RedmineHelpdesk::Patches::ContactsHelperPatch)
end
