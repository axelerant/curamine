namespace :redmine do
  namespace :contacts do

    desc <<-END_DESC
Drop settings.

  rake redmine:contacts:drop_settings RAILS_ENV="production" plugin="plugin_redmine_contacts"

Plugins:
  plugin_redmine_contacts: Redmine CRM plugin
  plugin_redmine_contacts_helpdesk: Redmine Helpdesk plugin
  plugin_redmine_contacts_invoices: Redmine Invoices plugin

END_DESC

    task :drop_settings => :environment do
      plugin_name = ENV['plugin']
      Setting[plugin_name.to_sym] = {} if plugin_name
    end

    desc <<-END_DESC
Set plugin settings.

  rake redmine:contacts:settings RAILS_ENV="production" plugin="plugin_redmine_contacts" setting="list_partial_style" value="list"
  rake redmine:contacts:settings RAILS_ENV="production" project="helpdesk" setting="contacts_show_deals_tab" value="1"

Plugins:
  plugin_redmine_contacts: Redmine CRM plugin
  plugin_redmine_contacts_helpdesk: Redmine Helpdesk plugin
  plugin_redmine_contacts_invoices: Redmine Invoices plugin

END_DESC

    task :settings => :environment do
      plugin_name = ENV['plugin']
      setting = ENV['setting']
      value = ENV['value']
      project = ENV['project']

      if (plugin_name.blank? && project.blank?) || setting.blank? || value.blank?
        puts "RedmineCRM: Params plugin, setting and value should be present"
        return
      end

      if project
        ContactsSetting[setting, Project.find(project).id] = value
      else
        plugin_settings = Setting[plugin_name.to_sym]
        plugin_settings[setting] = value
        Setting[plugin_name.to_sym] = plugin_settings
      end

    end

    desc <<-END_DESC
Load CRM plugin default data.
END_DESC

    task :load_default_data => :environment do
      DealStatus.create(:name  => l(:label_deal_status_pending), :status_type => DealStatus::OPEN_STATUS, :is_default => true, :color => "AAAAAA".hex)
      DealStatus.create(:name  => l(:label_deal_status_won), :status_type => DealStatus::WON_STATUS, :is_default => false, :color => "008000".hex)
      DealStatus.create(:name  => l(:label_deal_status_lost), :status_type => DealStatus::LOST_STATUS, :is_default => false, :color => "FF0000".hex)
    end




  end
end