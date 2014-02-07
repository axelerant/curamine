class JournalMessage < ActiveRecord::Base
  unloadable
  belongs_to :contact
  belongs_to :journal
  has_one :message_file, :class_name => "Attachment", :as  => :container, :dependent => :destroy

  acts_as_attachable :view_permission => :view_issues,  
                     :delete_permission => :edit_issues

  acts_as_activity_provider :type => 'helpdesk_tickets', 
                            :permission => :view_helpdesk_tickets,  
                            :timestamp => "#{table_name}.message_date",
                            :author_key => "#{Journal.table_name}.user_id",
                            :find_options => {:include => [{:journal => [{:issue => [:project, :tracker]}, :details, :user]}, :contact]}

  acts_as_event :title => Proc.new {|o| "#{o.journal.issue.tracker} ##{o.journal.issue.id}: #{o.journal.issue.subject}" if o.journal && o.journal.issue},
                :datetime => :message_date, 
                :group => :helpdesk_ticket,
                :project_key => "#{Project.table_name}.id",
                :url => Proc.new {|o| {:controller => 'issues', :action => 'show', :id => o.journal.issue.id, :anchor => "change-#{o.id}"} if o.journal},
                :type => Proc.new {|o| (o.is_incoming? ? "icon-email" : "icon-email-to")  },
                :author => Proc.new {|o|  o.is_incoming? ? o.contact : o.journal.user },
                :description => Proc.new{|o| o.journal.notes if o.journal}

  validates_presence_of :contact, :journal, :message_date

  def project
    journal.project
  end   

  def contact_name
  	contact.name
  end           

  def contact_email
  	contact.emails.first
  end	  

  def helpdesk_ticket
    journal.issue.helpdesk_ticket    
  end   

  def content
    journal.notes
  end
                     
end
