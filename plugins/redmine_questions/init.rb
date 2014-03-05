require 'redmine_questions'


Redmine::Plugin.register :redmine_questions do
  name 'Redmine Q&A plugin'
  author 'RedmineCRM'
  description 'This is a Q&A plugin for Redmine'
  version '0.0.5'
  url 'http://www.redminecrm.com/projects/questions'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.1.2'   
  
  settings :default => {
    :notice_message => '*Can\'t find the answer you\'re looking for?* Email us at ...'
  }, :partial => 'settings/questions'

  permission :view_questions, { 
    :questions => [:index, :autocomplete_for_topic, :topics]
  }

  delete_menu_item(:top_menu, :help)

  menu :top_menu, :questions, {:controller => 'questions', :action => 'index'}, 
    :last => true,
    :caption => :label_questions, 
    :if => Proc.new {User.current.allowed_to?({:controller => 'questions', :action => 'index'}, nil, {:global => true})}    

  Redmine::AccessControl.map do |map|
    map.project_module :boards do |map|
      map.permission :view_questions, {:questions => [:autocomplete_for_topic, :topics]}
      map.permission :vote_messages, {:questions => [:vote]}
      map.permission :convert_issues, {:questions => [:convert_issue]}
      map.permission :edit_messages_tags, {}
    end
  end    
end
