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

class ContactsProjectSetting
  unloadable

  def initialize(project, plugin_name)
    @project = project
    @plugin_settings_name = plugin_name
    Setting["plugin_" + @plugin_settings_name]
  end

  def method_missing(method_name, *args, &block)
    return super if /^(.*=)$/ =~ method_name.to_s
    setting_name = method_name.to_s.gsub(/\?|=/, '')
    setting_value = if ContactsSetting[@plugin_settings_name + '_' + setting_name,  @project].blank?
      if ContactsSetting.respond_to?(method_name)
        ContactsSetting.send(method_name)
      else
        Setting["plugin_" + @plugin_settings_name][setting_name]
      end
    else
      ContactsSetting[@plugin_settings_name + '_' + setting_name,  @project]
    end

    if /.*\?$/ =~ method_name.to_s
      setting_value.to_i > 0
    else
      setting_value
    end
  end
end
