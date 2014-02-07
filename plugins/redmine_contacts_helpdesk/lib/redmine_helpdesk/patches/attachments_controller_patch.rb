module RedmineHelpdesk
  module Patches

    module AttachmentsControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :read_authorize, :helpdesk
        end
      end

      module InstanceMethods
        def read_authorize_with_helpdesk
          unless params[:ticket_id] && params[:hash] && HelpdeskTicket.where(:id => params[:ticket_id]).first && HelpdeskTicket.where(:id => params[:ticket_id]).first.try(:token) == params[:hash]
            read_authorize_without_helpdesk
          end
        end

      end
    end
  end
end

unless AttachmentsController.included_modules.include?(RedmineHelpdesk::Patches::AttachmentsControllerPatch)
  AttachmentsController.send(:include, RedmineHelpdesk::Patches::AttachmentsControllerPatch)
end