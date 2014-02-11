match 'projects/:id/project_allocation', :controller => 'allocation', :action => 'by_project', :as => 'allocation_by_project'
match 'projects/:id/user_allocation', :controller => 'allocation', :action => 'by_user', :as => 'allocation_by_user'
