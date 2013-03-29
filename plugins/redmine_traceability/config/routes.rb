if Redmine::VERSION::MAJOR < 2
  ActionController::Routing::Routes.draw do |map|
    map.traceability '/projects/:project_id/traceability', :controller => 'mt', :action => 'index'
  end
else
  get '/projects/:project_id/traceability', :to => 'mt#index', :as => :traceability
end
