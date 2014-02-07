namespace :redmine do
  namespace :plugins do
    namespace :helpdesk do

      desc <<-END_DESC
Update Helpdesk tickets from issue contacts

Issue attributes control options:
  project=PROJECT          identifier of the target project
  status=STATUS            name of the target status
  tracker=TRACKER          name of the target tracker
  category=CATEGORY        name of the target category
  priority=PRIORITY        name of the target priority

Examples:

  rake redmine:plugins:helpdesk:update_tickets RAILS_ENV="production" \\
                  project=foo 
END_DESC

      task :update_tickets => :environment do
        return "project should be selected" unless ENV['project']

        project = Project.find(ENV['project'])
        issues = project.issues.includes(:contacts).where("contacts.id IS NOT NULL")
        issues.each do |issue| 
          if issue.helpdesk_ticket.blank? && issue.contacts && contact = issue.contacts.first
            helpdesk_ticket = HelpdeskTicket.new(:from_address => contact.primary_email,
                                                :to_address => HelpdeskSettings[:helpdesk_answer_from, project.id],
                                                :ticket_date => issue.created_on,
                                                :customer => contact,
                                                :issue => issue,
                                                :source => HelpdeskTicket::HELPDESK_EMAIL_SOURCE)
            message_file = issue.attachments.where(:filename => 'message.eml').first 
            helpdesk_ticket.message_file = message_file if message_file
            helpdesk_ticket.save
          end
        end

        JournalMessage.where(:message_date => nil).each do |message|
          message.message_date = message.journal.created_on if message.journal
          message.save
        end
        Attachment.where(:container_type => 'ContactJournal').update_all(:container_type => 'JournalMessage')

      end

      
    end  
  end
end
