if Rails::VERSION::MAJOR < 3

    ActionController::Routing::Routes.draw do |map|
        map.project_destroy_confirm('projects/:id/destroy', :controller => 'projects', :action => 'destroy', :conditions => { :method => :get })
    end

else

    get 'projects/:id/destroy', :to => 'projects#destroy', :as => 'project_destroy_confirm'

end
