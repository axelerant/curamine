module RedmineHelpdesk
  module Patches    
    
    module IssuesControllerPatch
      def self.included(base) # :nodoc: 
        base.send(:include, InstanceMethods)
        
        base.class_eval do 
          unloadable   
          before_filter :apply_helpdesk_macro, :only => :update 
          after_filter :send_helpdesk_response, :only => :update 
          after_filter :send_auto_answer, :only => :create

          alias_method_chain :build_new_issue_from_params, :helpdesk
          helper :helpdesk
        end  
      end      

      module InstanceMethods    

        def send_helpdesk_response  
          return unless check_send_helpdesk_response? &&  @issue.current_journal &&  !@issue.current_journal.notes.blank? 
          begin
            if msg = HelpdeskMailer.issue_response(@issue.customer, @issue.current_journal, params).deliver

              JournalMessage.create(:to_address => msg.to_addrs.first,
                                    :is_incoming => false,
                                    :message_date => Time.now,
                                    :message_id => msg.message_id,
                                    :source => HelpdeskTicket::HELPDESK_EMAIL_SOURCE,
                                    :cc_address => msg.cc.join(', '),
                                    :bcc_address => msg.bcc.join(', '), 
                                    :contact => @issue.customer,
                                    :journal => @issue.current_journal)
                                    
              flash[:notice].blank? ? flash[:notice] = l(:notice_email_sent, "<span class='icon icon-email'>" + msg.to_addrs.first  + "</span>") : flash[:notice] << " " + l(:notice_email_sent, "<span class='icon icon-email'>" + msg.to_addrs.first  + "</span>")
            end
          rescue Exception => e
            flash[:error].blank? ? flash[:error] = e.message : flash[:error] << " " + e.message
          end    
        end 

        def send_auto_answer
          return unless @issue && @issue.customer && User.current.allowed_to?(:send_response, @project) 
          msg = HelpdeskMailer.auto_answer(@issue.customer, @issue).deliver if params[:helpdesk_send_auto_answer]
          flash[:notice].blank? ? flash[:notice] = l(:notice_email_sent, "<span class='icon icon-email'>" + msg.to_addrs.first  + "</span>") : flash[:notice] << " " + l(:notice_email_sent, "<span class='icon icon-email'>" + msg.to_addrs.first  + "</span>") if msg
        rescue Exception => e
            flash[:error].blank? ? flash[:error] = e.message : flash[:error] << " " + e.message
        end

        def apply_helpdesk_macro
          return unless check_send_helpdesk_response? 
          notes = (params[:notes] || (params[:issue].present? ? params[:issue][:notes] : nil))
          return if notes.blank?
          params[:notes] = HelpdeskMailer.apply_macro(notes, @issue.customer, @issue, User.current) 
          params[:issue][:notes] = params[:notes] if params[:issue].present?
        end
        
        def check_send_helpdesk_response?
          !@conflict && 
              @issue &&
              @issue.valid? &&
              @issue.customer &&
              params[:helpdesk] && !params[:helpdesk][:is_send_mail].blank? && 
              @project.module_enabled?(:contacts_helpdesk) && 
              User.current.allowed_to?(:send_response, @project) 
        end 

        def build_new_issue_from_params_with_helpdesk
          build_new_issue_from_params_without_helpdesk
          return unless @issue
          contact = Contact.visible.find_by_id((params[:helpdesk_ticket] && params[:helpdesk_ticket][:contact_id]) || params[:customer_id])
          @issue.helpdesk_ticket = HelpdeskTicket.new(:issue => @issue, :ticket_date => Time.now, :customer => contact) if contact
        end

      end
    end
  end
end  

unless IssuesController.included_modules.include?(RedmineHelpdesk::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineHelpdesk::Patches::IssuesControllerPatch)
end
