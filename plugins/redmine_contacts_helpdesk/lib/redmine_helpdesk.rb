Rails.configuration.to_prepare do
  require 'redmine_helpdesk/patches/issues_controller_patch'
  require 'redmine_helpdesk/patches/journals_controller_patch'
  require 'redmine_helpdesk/patches/attachments_controller_patch'
  require 'redmine_helpdesk/patches/issue_patch'
  require 'redmine_helpdesk/patches/journal_patch'
  require 'redmine_helpdesk/patches/contact_patch'
  require 'redmine_helpdesk/patches/issue_query_patch'
  require 'redmine_helpdesk/patches/queries_helper_patch'
  require 'redmine_helpdesk/patches/projects_helper_patch'
  require 'redmine_helpdesk/patches/contacts_helper_patch'
  require 'redmine_helpdesk/patches/application_helper_patch'
  require 'redmine_helpdesk/patches/mail_handler_patch'
end

require 'redmine_helpdesk/hooks/view_layouts_hook'
require 'redmine_helpdesk/hooks/view_issues_hook'
require 'redmine_helpdesk/hooks/view_projects_hook'
require 'redmine_helpdesk/hooks/view_contacts_hook'
require 'redmine_helpdesk/hooks/view_journals_hook'
require 'redmine_helpdesk/hooks/model_issue_hook'
require 'redmine_helpdesk/hooks/controller_contacts_duplicates_hook'

require 'redmine_helpdesk/wiki_macros/helpdesk_wiki_macro'

class HelpdeskSettings
  MACRO_LIST = %w({%contact.first_name%} {%contact.name%} {%contact.company%} {%contact.last_name%}
    {%contact.middle_name%} {%date%} {%ticket.assigned_to%} {%ticket.id%} {%ticket.tracker%}
    {%ticket.project%} {%ticket.subject%} {%ticket.quoted_description%} {%ticket.history%} {%ticket.status%}
    {%ticket.priority%} {%ticket.estimated_hours%} {%ticket.done_ratio%} {%ticket.public_url%}
    {%response.author%} {%response.author.first_name%})

  # Returns the value of the setting named name
  def self.[](name, project_id)
    project_id = project_id.id if project_id.is_a?(Project)
    !ContactsSetting[name, project_id].blank? ? ContactsSetting[name, project_id] : RedmineHelpdesk.settings[name]
  end
end

module RedmineHelpdesk
  module ContactUserMethods
    def name(formatter = nil)
      f = self.class.name_formatter(formatter)
      if formatter
        eval('"' + f[:string] + '"')
      else
        @name ||= eval('"' + f[:string] + '"')
      end
    end
  end

  def self.settings() Setting[:plugin_redmine_contacts_helpdesk] ? Setting[:plugin_redmine_contacts_helpdesk] : {} end

  def self.public_title
    self.settings[:helpdesk_public_title]
  end

  def self.public_tickets?
    self.settings[:helpdesk_public_tickets].to_i > 0
  end

  def self.public_comments?
    self.settings[:helpdesk_public_comments].to_i > 0
  end

  def self.public_spent_time?
    self.settings[:helpdesk_public_show_spent_time].to_i > 0
  end

end

