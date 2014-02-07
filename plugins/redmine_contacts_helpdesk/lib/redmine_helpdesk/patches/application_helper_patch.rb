require_dependency 'application_helper'

module RedmineHelpdesk
  module Patches
    module ApplicationHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :avatar, :helpdesk          
          alias_method_chain :link_to_user, :helpdesk          
        end
      end


      module InstanceMethods
        # include ContactsHelper

        def avatar_with_helpdesk(user, options = { })
          if user.is_a?(Contact)
            avatar_to(user, options)  
          else
            avatar_without_helpdesk(user, options)
          end
        end

        def link_to_user_with_helpdesk(user, options={})
          if user.is_a?(Contact)
            link_to_source(user, options)
          else
            link_to_user_without_helpdesk(user, options)
          end
        end        
        
      end
      
    end
  end
end

unless ApplicationHelper.included_modules.include?(RedmineHelpdesk::Patches::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedmineHelpdesk::Patches::ApplicationHelperPatch)
end
