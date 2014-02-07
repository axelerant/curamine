module RedmineHelpdesk
  module Patches    
    
    module JournalPatch
      def self.included(base) # :nodoc: 
        base.send(:include, InstanceMethods)
        
        base.class_eval do    
          unloadable # Send unloadable so it will not be unloaded in development
          has_one :contact, :through => :journal_message
          has_one :journal_message, :dependent => :delete
        end  
      end  


      module InstanceMethods

        def is_incoming?
          self.journal_message && self.journal_message.is_incoming?
        end

        def is_sent?
          self.journal_message && !self.journal_message.is_incoming?
        end

        def message_author
          self.is_incoming? ? self.contact : self.user
        end

      end 

    end
  end
end

unless Journal.included_modules.include?(RedmineHelpdesk::Patches::JournalPatch)
  Journal.send(:include, RedmineHelpdesk::Patches::JournalPatch)
end
    