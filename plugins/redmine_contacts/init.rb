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

CONTACTS_VERSION_NUMBER = '3.2.13'
CONTACTS_VERSION_STATUS = ''

ActiveRecord::Base.observers += [:contact_observer, :note_observer]
ActiveRecord::Base.observers += [:deal_observer]

Redmine::Plugin.register :redmine_contacts do
  name 'Redmine CRM plugin'
  author 'RedmineCRM'
  description 'This is a CRM plugin for Redmine that can be used to track contacts and deals information'
  version CONTACTS_VERSION_NUMBER + '-pro' + CONTACTS_VERSION_STATUS

  url 'http://redminecrm.com'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.1.2'

  settings :default => {
    :use_gravatars => false,
    :name_format => :lastname_firstname.to_s,
    :auto_thumbnails  => true,
    :major_currencies => "USD, EUR, GBP, RUB, CHF",
    :contact_list_default_columns => ["first_name", "last_name"],
    :max_thumbnail_file_size => 300
  }, :partial => 'settings/contacts/contacts'
  project_module :deals do
    permission :delete_deals, :deals => [:destroy, :bulk_destroy]
    permission :view_deals, {
      :deals => [:index, :show, :context_menu],
      :notes => [:show],
      :sales_funnel => [:index], :public => true
    }
    permission :edit_deals, {
      :deals => [:edit, :update, :add_attachment, :bulk_update, :bulk_edit, :update_form],
      :deal_contacts => [:add, :delete],
      :notes =>  [:create, :destroy, :update]
    }
    permission :add_deals, {
      :deals => [:new, :create, :update_form]
    }

    permission :manage_deals, {
      :deal_categories => [:new, :edit, :destroy],
      :deal_statuses => [:assing_to_project], :require => :member
    }

    permission :import_deals, {:deal_imports => [:new, :create]}
  end

  project_module :contacts do
    permission :view_contacts, {
      :contacts => [:show, :index, :live_search, :contacts_notes, :context_menu],
      :notes => [:show]
    }
    permission :view_private_contacts, {
      :contacts => [:show, :index, :live_search, :contacts_notes, :context_menu],
      :notes => [:show]
    }

    permission :add_contacts, {
      :contacts => [:new, :create],
      :contacts_duplicates => [:index, :duplicates],
      :contacts_vcf => [:load]
    }

    permission :edit_contacts, {
      :contacts => [:edit, :update, :bulk_update, :bulk_edit],
      :notes => [:create, :destroy, :edit, :update],
      :contacts_issues => [:new, :create_issue, :create, :delete, :close, :autocomplete_for_contact],
      :contacts_duplicates => [:index, :merge, :duplicates],
      :contacts_projects => [:add, :delete],
      :contacts_vcf => [:load]
    }
    permission :delete_contacts, :contacts => [:destroy, :bulk_destroy]
    permission :add_notes, :notes => [:create]
    permission :delete_notes, :notes => [:destroy, :edit, :update]
    permission :delete_own_notes, :notes => [:destroy, :edit, :update]

    permission :manage_contacts, {
      :projects => :settings,
      :contacts_settings => :save,
    }
    permission :import_contacts, {:contact_imports => [:new, :create]}
    permission :send_contacts_mail, :contacts => [:edit_mails, :send_mails, :preview_email]
    permission :manage_public_contacts_queries, {:contacts_queries => [:new, :create, :edit, :update, :destroy]}, :require => :member
    permission :save_contacts_queries, {:contacts_queries => [:new, :create, :edit, :update, :destroy]}, :require => :loggedin

  end

  menu :project_menu, :contacts, {:controller => 'contacts', :action => 'index'}, :caption => :contacts_title, :param => :project_id
  menu :top_menu, :contacts,
                          {:controller => 'contacts', :action => 'index', :project_id => nil},
                          :caption => :label_contact_plural,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'contacts', :action => 'index'},
                                          nil, {:global => true})  && ContactsSetting.contacts_show_in_top_menu? }

  menu :application_menu, :contacts,
                          {:controller => 'contacts', :action => 'index'},
                          :caption => :label_contact_plural,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'contacts', :action => 'index'},
                                          nil, {:global => true})  && ContactsSetting.contacts_show_in_app_menu? }
  menu :top_menu, :deals,
                          {:controller => 'deals', :action => 'index', :project_id => nil},
                          :caption => :label_deal_plural,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'deals', :action => 'index'},
                                          nil, {:global => true}) && ContactsSetting.deals_show_in_top_menu? }
  menu :application_menu, :deals,
                          {:controller => 'deals', :action => 'index'},
                          :caption => :label_deal_plural,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'deals', :action => 'index'},
                                          nil, {:global => true}) && ContactsSetting.deals_show_in_app_menu? }

  menu :project_menu, :deals, {:controller => 'deals', :action => 'index' },
                              :caption => :label_deal_plural,
                              :param => :project_id


  menu :admin_menu, :contacts, {:controller => 'settings', :action => 'plugin', :id => "redmine_contacts"}, :caption => :contacts_title

  activity_provider :contacts, :default => false, :class_name => ['ContactNote', 'Contact']
  activity_provider :deals, :default => false, :class_name => ['DealNote', 'Deal']

  Redmine::Search.map do |search|
    search.register :contacts
    search.register :contact_notes
    search.register :deals
    search.register :deal_notes
  end

end

require 'redmine_contacts'
