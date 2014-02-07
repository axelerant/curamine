require 'redmine'

Redmine::Plugin.register :redmine_contacts_helpdesk do
  name 'Redmine Helpdesk plugin'
  author 'RedmineCRM'
  description 'This is a Helpdesk plugin for Redmine'
  version '2.2.7-pro'
  url 'http://redminecrm.com'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.1.2'
  requires_redmine_plugin :redmine_contacts, :version_or_higher => '3.2.10'

  settings :default => {
    :helpdesk_answer_from => '',
    :helpdesk_add_contact_notes => '1',
    :helpdesk_answer_subject => 'Re: {%ticket.subject%} [{%ticket.tracker%} #{%ticket.id%}]',
    :helpdesk_first_answer_subject => '{%ticket.project%} support message [{%ticket.tracker%} #{%ticket.id%}]',
    :helpdesk_first_answer_template => "Hello, {%contact.first_name%}\n\nWe hereby confirm that we have received your message.\n\nWe will handle your request and get back to you as soon as possible.\n\nYour request has been assigned the following case ID #\{%ticket.id%}."
  }, :partial => 'settings/helpdesk'

  project_module :contacts_helpdesk do
     permission :view_helpdesk_tickets, :helpdesk => [:show_original],
                                        :canned_responses => [:add]
     permission :view_helpdesk_reports, :helpdesk_reports => [:tickets_report, :staff_report, :index]
     permission :send_response, :issues => [:send_helpdesk_response, :email_note],
                                :helpdesk => [:show_original, :create_ticket, :delete_spam]
     permission :edit_helpdesk_settings, :helpdesk => [:save_settings, :get_mail]
     permission :edit_helpdesk_tickets, :helpdesk_tickets => [:update, :edit, :destroy]
     # Canned responses
     permission :manage_public_canned_responses, {:canned_responses => [:new, :create, :edit, :update, :destroy]}, :require => :member
     permission :manage_canned_responses, {:canned_responses => [:new, :create, :edit, :update, :destroy]}, :require => :loggedin
  end

  menu :admin_menu, :helpdesk, {:controller => 'settings', :action => 'plugin', :id => "redmine_contacts_helpdesk"}, :caption => :label_helpdesk, :param => :project_id

  activity_provider :helpdesk_tickets, :default => false, :class_name => ['HelpdeskTicket', 'JournalMessage']

end

require 'redmine_helpdesk'
