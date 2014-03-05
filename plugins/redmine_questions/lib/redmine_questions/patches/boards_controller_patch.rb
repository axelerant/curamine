require_dependency 'boards_controller'  
require_dependency 'board' 

module RedmineQuestions
  module Patches    

    module BoardsControllerPatch
      def self.included(base) # :nodoc: 
        base.class_eval do 
          helper :questions
        end  
      end
        
    end
    
  end
end  

unless MessagesController.included_modules.include?(RedmineQuestions::Patches::BoardsControllerPatch)
  MessagesController.send(:include, RedmineQuestions::Patches::BoardsControllerPatch)
end
