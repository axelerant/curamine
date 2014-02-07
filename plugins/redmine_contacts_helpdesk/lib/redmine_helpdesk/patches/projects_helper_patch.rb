require_dependency 'queries_helper'

module RedmineHelpdesk
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :project_settings_tabs, :helpdesk          
        end
      end


      module InstanceMethods
        # include ContactsHelper

        def project_settings_tabs_with_helpdesk
          tabs = project_settings_tabs_without_helpdesk
          tabs.push({ :name => 'helpdesk',
            :action => :edit_helpdesk_settings,
            :partial => 'projects/settings/helpdesk_settings',
            :label => :label_helpdesk })
          tabs.push({ :name => 'helpdesk_template',
            :action => :edit_helpdesk_settings,
            :partial => 'projects/settings/helpdesk_template',
            :label => :label_helpdesk_template })          
          tabs.push({ :name => 'helpdesk_canned_responses',
            :action => :manage_canned_responses,
            :partial => 'projects/settings/helpdesk_canned_responses',
            :label => :label_helpdesk_canned_response_plural })          

          tabs.select {|tab| User.current.allowed_to?(tab[:action], @project)}
        end
        
      end
      
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineHelpdesk::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineHelpdesk::Patches::ProjectsHelperPatch)
end
