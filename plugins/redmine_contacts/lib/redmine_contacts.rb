# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require_dependency 'redmine_contacts/utils/thumbnail'
require_dependency 'redmine_contacts/utils/check_mail'
require_dependency 'redmine_contacts/contacts_project_setting'

# Patches
require_dependency 'redmine_contacts/patches/compatibility_patch'
ActionDispatch::Reloader.to_prepare do
	require_dependency 'redmine_contacts/patches/issue_patch'
	require_dependency 'redmine_contacts/patches/project_patch'
  require_dependency 'redmine_contacts/patches/mailer_patch'
	require_dependency 'redmine_contacts/patches/notifiable_patch'
	require_dependency 'redmine_contacts/patches/application_controller_patch'
	require_dependency 'redmine_contacts/patches/attachments_controller_patch'
	require_dependency 'redmine_contacts/patches/auto_completes_controller_patch'
	require_dependency 'redmine_contacts/patches/users_controller_patch'
	require_dependency 'redmine_contacts/patches/my_controller_patch'
	require_dependency 'redmine_contacts/patches/projects_controller_patch'
	require_dependency 'redmine_contacts/patches/issues_controller_patch'
  require_dependency 'redmine_contacts/patches/issue_query_patch'
	require_dependency 'redmine_contacts/patches/custom_fields_helper_patch'
  require_dependency 'redmine_contacts/patches/queries_helper_patch'
  require_dependency 'redmine_contacts/patches/projects_helper_patch'
  require_dependency 'redmine_contacts/patches/settings_controller_patch'
	# require_dependency 'redmine_contacts/patches/settings_helper_patch'
end

require_dependency 'redmine_contacts/wiki_macros/contacts_wiki_macros'

# Hooks
require_dependency 'redmine_contacts/hooks/views_projects_hook'
require_dependency 'redmine_contacts/hooks/views_issues_hook'
require_dependency 'redmine_contacts/hooks/views_layouts_hook'
require_dependency 'redmine_contacts/hooks/views_users_hook'
require_dependency 'redmine_contacts/hooks/views_custom_fields_hook'
require_dependency 'redmine_contacts/hooks/controllers_time_entry_reports_hook'

# Plugins
require 'acts_as_viewable/init'
require 'acts_as_taggable_on_patch'

require 'redmine_contacts/liquid/liquid' if Gem::Specification.find_all_by_name('liquid').any?

module RedmineContacts

  def self.companies_select
  	RedmineContacts.settings["select_companies_to_deal"]
  end

  def self.cross_project_contacts?
  	!!RedmineContacts.settings["cross_project_contacts"]
  end

  def self.settings() Setting[:plugin_redmine_contacts].blank? ? {} : Setting[:plugin_redmine_contacts]  end

  def self.default_list_style
    return (%w(list list_excerpt list_cards) && [RedmineContacts.settings["default_list_style"]]).first || "list_excerpt"
    return 'list_excerpt'
  end

end
