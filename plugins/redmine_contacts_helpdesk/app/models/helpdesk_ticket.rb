class HelpdeskTicket < ActiveRecord::Base
  HELPDESK_EMAIL_SOURCE = 0
  HELPDESK_WEB_SOURCE = 1
  HELPDESK_PHONE_SOURCE = 2
  HELPDESK_TWITTER_SOURCE = 3
  HELPDESK_CONVERSATION_SOURCE = 4

  attr_accessor :ticket_time

  unloadable
  belongs_to :customer, :class_name => 'Contact', :foreign_key => 'contact_id'   
  belongs_to :issue
  has_one :message_file, :class_name => "Attachment", :as  => :container, :dependent => :destroy

  acts_as_attachable :view_permission => :view_issues,  
                     :delete_permission => :edit_issues


  acts_as_activity_provider :type => 'helpdesk_tickets', 
                            :permission => :view_helpdesk_tickets,  
                            :timestamp => "#{table_name}.ticket_date",
                            :find_options => {:include => {:issue => :project}},
                            :author_key => "#{Issue.table_name}.author_id"


  acts_as_event :datetime => :ticket_date, 
                :project_key => "#{Project.table_name}.id",
                :url => Proc.new {|o| {:controller => 'issues', :action => 'show', :id => o.issue_id}},  
                :type => Proc.new {|o| 'icon-email' + (o.issue.closed? ? ' closed' : '') if o.issue },  
                :title => Proc.new {|o| "##{o.issue.id} (#{o.issue.status}): #{o.issue.subject}" if o.issue },
                :author => Proc.new {|o|  o.customer},
                :description => Proc.new{|o| o.issue.description if o.issue}

  accepts_nested_attributes_for :customer

  validates_presence_of :customer, :issue, :ticket_date

  def ticket_time
    self.ticket_date.to_s(:time) unless self.ticket_date.blank?
  end

  def ticket_time=(val)
    if !self.ticket_date.blank? && val.to_s.gsub(/\s/, "").match(/^(\d{1,2}):(\d{1,2})$/)
      self.ticket_date = self.ticket_date.change({:hour => $1.to_i % 24, :min => $2.to_i % 60})    
    end
  end

  def recalculate_events
    unless issue.closed?
      close_journal_id = nil
    end
  end

  def available_addresses
    @available_addresses ||= ([self.default_to_address] | self.customer.emails.map{|e| e} | [self.from_address.blank? ? nil : self.from_address.downcase.strip]).compact.uniq if self.customer
  end

  def default_to_address
    address = self.from_address.blank? ? "" : self.from_address.downcase.strip
    self.customer.emails.include?(address) ? address : self.customer.primary_email
  end

  def cc_addresses
    @cc_addresses = ((self.issue.contacts ? self.issue.contacts.map(&:primary_email) : []) | cc_address.to_s.split(',')).compact.uniq
  end
                     
  def project
    issue.project if issue
  end   

  def author
    issue.author if issue
  end

  def customer_name
  	customer.name if customer
  end 

  def ticket_source_name
    case self.source
      when HelpdeskTicket::HELPDESK_EMAIL_SOURCE then l(:label_helpdesk_tickets_email) 
      when HelpdeskTicket::HELPDESK_PHONE_SOURCE then l(:label_helpdesk_tickets_phone) 
      when HelpdeskTicket::HELPDESK_WEB_SOURCE then l(:label_helpdesk_tickets_web) 
      when HelpdeskTicket::HELPDESK_TWITTER_SOURCE then l(:label_helpdesk_tickets_twitter) 
      when HelpdeskTicket::HELPDESK_CONVERSATION_SOURCE then l(:label_helpdesk_tickets_conversation) 
      else ""
    end
  end    

  def ticket_source_icon
    case self.source
      when HelpdeskTicket::HELPDESK_EMAIL_SOURCE then "icon-email" 
      when HelpdeskTicket::HELPDESK_PHONE_SOURCE then "icon-call" 
      when HelpdeskTicket::HELPDESK_WEB_SOURCE then "icon-web" 
      when HelpdeskTicket::HELPDESK_TWITTER_SOURCE then "icon-twitter" 
      else "icon-helpdesk"
    end
  end       

  def content
    issue.description if issue   
  end   

  def customer_email
  	customer.primary_email if customer
  end

  def last_message
    @last_message ||= JournalMessage.includes(:journal => :issue).where(:issues => {:id => issue.id}).order("#{Journal.table_name}.created_on ASC").last || self
  end

  def last_message_date
    last_message.is_a?(HelpdeskTicket) ? self.ticket_date : last_message.message_date if last_message
  end

  def ticket_date
    return nil if super.blank?
    zone = User.current.time_zone
    zone ? super.in_time_zone(zone) : (super.utc? ? super.localtime : super)
  end

  def token
    Digest::MD5.hexdigest("#{issue.id}:#{ticket_date.strftime('%d.%m.%Y %H:%M:%S')}:#{Rails.application.config.secret_token}")
  end
                     
end
