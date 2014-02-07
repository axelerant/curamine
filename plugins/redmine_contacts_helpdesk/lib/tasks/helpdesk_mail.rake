namespace :redmine do
  namespace :email do
    namespace :helpdesk do

      desc <<-END_DESC
Read an email from standard input.

Issue attributes control options:
  project=PROJECT          identifier of the target project
  status=STATUS            name of the target status
  tracker=TRACKER          name of the target tracker
  category=CATEGORY        name of the target category
  priority=PRIORITY        name of the target priority

Examples:

  rake redmine:email:helpdesk:read RAILS_ENV="production" \\
                  project=foo \\
                  tracker=bug < raw_email
END_DESC

      task :read => :environment do
        options = { :issue => {} }
        %w(project project_id status assigned_to tracker category priority due_date).each { |a| options[:issue][a.to_sym] = ENV[a] if ENV[a] }
        options[:reopen_status] = ENV['reopen_status'] if ENV['reopen_status']
        options[:issue][:project_id] = options[:issue][:project]  

        HelpdeskMailer.receive(STDIN.read, options)
      end

      desc <<-END_DESC
Read emails from an IMAP server.


Available IMAP options:
  host=HOST                IMAP server host (default: 127.0.0.1)
  port=PORT                IMAP server port (default: 143)
  ssl=SSL                  Use SSL? (default: false)
  username=USERNAME        IMAP account
  password=PASSWORD        IMAP password
  folder=FOLDER            IMAP folder to read (default: INBOX)

Issue attributes control options:
  project_id=PROJECT_ID    identifier of the target project
  status=STATUS            name of the target status
  tracker=TRACKER          name of the target tracker
  category=CATEGORY        name of the target category
  priority=PRIORITY        name of the target priority
  reopen_status=STATUS     name of the target status afret receive response

Processed emails control options:
  move_on_success=MAILBOX  move emails that were successfully received
                           to MAILBOX instead of deleting them
  move_on_failure=MAILBOX  move emails that were ignored to MAILBOX

Examples:
  rake redmine:email:helpdesk:receive_imap RAILS_ENV="production" \\
    host=imap.foo.bar username=redmine@example.net password=xxx ssl=1 \\
    project=foo \\
    tracker=bug
END_DESC

      task :receive_imap => :environment do
        imap_options = {:host => ENV['host'],
                        :port => ENV['port'],
                        :ssl => ENV['ssl'],
                        :username => ENV['username'],
                        :password => ENV['password'],
                        :folder => ENV['folder'],
                        :move_on_success => ENV['move_on_success'],
                        :move_on_failure => ENV['move_on_failure']}

        options = { :issue => {} }
        %w(project_id project status assigned_to tracker category priority due_date).each { |a| options[:issue][a.to_sym] = ENV[a] if ENV[a] }
        options[:reopen_status] = ENV['reopen_status'] if ENV['reopen_status']
        options[:issue][:project_id] = options[:issue][:project]  

        RedmineContacts::Mailer.check_imap(HelpdeskMailer, imap_options, options)
      end

      desc <<-END_DESC
Read emails from an POP3 server.

Available POP3 options:
  host=HOST                POP3 server host (default: 127.0.0.1)
  port=PORT                POP3 server port (default: 110)
  username=USERNAME        POP3 account
  password=PASSWORD        POP3 password
  apop=1                   use APOP authentication (default: false)
  delete_unprocessed=1     delete messages that could not be processed
                           successfully from the server (default
                           behaviour is to leave them on the server)

See redmine:email:helpdesk:receive_pop3 for more options and examples.
END_DESC

      task :receive_pop3 => :environment do
        pop_options  = {:host => ENV['host'],
                        :port => ENV['port'],
                        :apop => ENV['apop'],
                        :username => ENV['username'],
                        :password => ENV['password'],
                        :delete_unprocessed => ENV['delete_unprocessed']}

        options = { :issue => {} }
        %w(project_id project status assigned_to tracker category priority due_date).each { |a| options[:issue][a.to_sym] = ENV[a] if ENV[a] }
        options[:reopen_status] = ENV['reopen_status'] if ENV['reopen_status']
        options[:issue][:project_id] = options[:issue][:project]  

        RedmineContacts::Mailer.check_pop3(HelpdeskMailer, pop_options, options)
      end
      
      desc <<-END_DESC
Receive emails using project settings.

rake redmine:email:helpdesk:receive RAILS_ENV="production"

END_DESC

      task :receive => :environment do
        Project.active.has_module(:contacts_helpdesk).each do |project|
          begin
            HelpdeskMailer.check_project(project.id)                
          rescue Exception => e   
             logger.error "Helpdesk MailHandler: can't get mail for project #{project.name} with error: #{e.message}" if logger && logger.error
             puts "Helpdesk MailHandler: can't get mail for project #{project.name} with error: #{e.message}"
          end  
        end
      end
      
    end  
  end
end
