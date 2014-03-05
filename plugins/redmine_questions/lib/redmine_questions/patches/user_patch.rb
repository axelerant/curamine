module RedmineQuestions
  module Patches
    module UserPatch
      def self.included(base) # :nodoc: 
        base.class_eval do    
          unloadable # Send unloadable so it will not be unloaded in development
          acts_as_voter
        end  
      end  
    end
  end
end

unless User.included_modules.include?(RedmineQuestions::Patches::UserPatch)
  User.send(:include, RedmineQuestions::Patches::UserPatch)
end
