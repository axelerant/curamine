require 'redmine'

require_dependency 'allocation/hooks'
require_dependency 'allocation/patches/members_controller_patch.rb'

Redmine::Plugin.register :redmine_allocation do
  Rails.configuration.after_initialize do
    locale = if Setting.table_exists?
               Setting.default_language
             else
               'en'
             end

    I18n.with_locale(locale) do
      name I18n.t :'allocation.plugin_name'
      description I18n.t :'allocation.plugin_description'
      author 'Emergya'
      version '1.1.2'
    end
  end

  settings :default => {}, :partial => 'settings/redmine_allocation'
  Redmine::AccessControl.permission(:manage_members).instance_variable_get(:@actions) << "allocation/by_user" << "allocation/by_project"
end
