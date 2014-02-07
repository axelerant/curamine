module RedmineHelpdesk
  module Patches
    module MailHandlerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          if Redmine::VERSION.to_s > "2.2"
            alias_method_chain :receive_issue_reply, :handle_helpdesk
          else
            alias_method_chain :receive_issue_reply, :handle_helpdesk_2_1
          end 
        end
      end

      module InstanceMethods
        def receive_issue_reply_with_handle_helpdesk(issue_id, from_journal=nil)
          journal = receive_issue_reply_without_handle_helpdesk(issue_id, from_journal)
          helpdesk_receive_issue_reply(issue_id, journal, from_journal)
        end

        def receive_issue_reply_with_handle_helpdesk_2_1(issue_id)
          journal = receive_issue_reply_without_handle_helpdesk_2_1(issue_id)
          helpdesk_receive_issue_reply(issue_id, journal)
        end

        private 

        def helpdesk_receive_issue_reply(issue_id, journal, from_journal=nil)
          return unless journal
          return journal if journal.notes.blank?
          project = journal.issue.project
          return journal unless journal.user.allowed_to?(:send_response, journal.issue.project) && journal.issue.customer

          unless HelpdeskSettings[:send_note_by_default, project]
            regexp = /^@@sendmail@@\s*$/
            return journal unless journal.notes.match(regexp)
            journal.notes = journal.notes.gsub(regexp, '')
          end

          contact = journal.issue.customer

          begin
            params = {}
            if msg = HelpdeskMailer.issue_response(contact, journal, params).deliver

              JournalMessage.create(:to_address => msg.to_addrs.first,
                                    :is_incoming => false,
                                    :message_date => Time.now,
                                    :message_id => msg.message_id,
                                    :source => HelpdeskTicket::HELPDESK_EMAIL_SOURCE,
                                    :cc_address => msg.cc.join(', '),
                                    :bcc_address => msg.bcc.join(', '), 
                                    :contact => contact,
                                    :journal => journal)
              journal.issue.assigned_to = User.current unless journal.issue.assigned_to
              journal.issue.status_id = HelpdeskSettings[:helpdesk_new_status, journal.issue.project_id] unless HelpdeskSettings[:helpdesk_new_status, journal.issue.project_id].blank?
              journal.issue.save
            end

            logger.info  "Helpdesk: mail sent to #{contact.name} - [#{contact.emails.first}]" if logger && logger.info
          rescue Exception => e
            logger.info  "Helpdesk: error of mail sending to #{contact.name} - [#{contact.emails.first}], #{e.message}" if logger && logger.info
          end    

          journal.save!
          journal
        end

      end   

    end
  end
end  

unless MailHandler.included_modules.include?(RedmineHelpdesk::Patches::MailHandlerPatch)
  MailHandler.send(:include, RedmineHelpdesk::Patches::MailHandlerPatch)
end
