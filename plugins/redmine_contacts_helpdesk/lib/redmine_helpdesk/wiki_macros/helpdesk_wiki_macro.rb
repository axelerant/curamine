module RedmineHelpdesk
  module WikiMacros

    Redmine::WikiFormatting::Macros.register do
      desc "Mail icon Macro" 
      macro :mail do |obj, args|
        "<span class=\"icon icon-email\"/>"
      end  

    end  

  end
end
