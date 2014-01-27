RedmineApp::Application.routes.draw do
  resources :init_select
  #resources :process_models
  get 'projects/:project_id/select_models', :to => 'init_select#select_models'
  match 'pojects/:project_id/import_pf', :controller=>'init_select', :action=>'import_process_framework'
  get 'prjects/:project_id/remove_model', :controller=>'init_select', :action=>'remove_model'
  get 'projects/:project_id/model/:selected_model/select_activities/',:controller => 'init_select', :action => 'select_activities'
  get 'projects/:project_id/view_process_framework', :controller => 'init_select', :action => 'view_process_framework'
  match 'projects/:project_id/export_process_framework', :controller => 'init_select', :action => 'export_process_framework'
  match 'projects/:project_id/save_process_framework', :controller => 'init_select', :action => 'save_process_framework', :via => :post
  match 'projects/:project_id/show_details', :controller => 'init_select', :action => 'show_details', :via => :post

  get 'admin_process_models', :controller => 'admin_process_models', :action => 'index'
  get ':parent_type/:parent_id/show_subs', :controller => 'admin_process_models', :action => 'show_subs'
  get ':type/new', :controller => 'admin_process_models', :action => 'new_elem'
  get ':type/:parent_id/new', :controller => 'admin_process_models', :action => 'new_elem'
  get ':type/:elem/show_details', :controller => 'admin_process_models', :action => 'show_details'
  put ':type/:elem/update_elem', :controller => 'admin_process_models', :action=>'update_elem'
  match 'process_models/sort',:controller => 'admin_process_models', :action=>'sort_model', :via => :post
  get 'process_models/open_close/:elem',:controller => 'admin_process_models', :action=>'open_close_model'

  match 'process_models/sort_elem',:controller => 'admin_process_models', :action=>'sort_elem', :via => :post
  get 'process_models/show_subs',:controller => 'admin_process_models', :action=>'show_subs'
  get 'process_models/remove/:parent_id/:type/:elem',:controller => 'admin_process_models', :action=>'remove_elem'
  match 'process_models/add_elem',:controller => 'admin_process_models', :action=>'add_elem'
  get 'process_models/:type/del/:elem',:controller => 'admin_process_models', :action=>'delete_elem'
  match 'process_models/save_elem',:controller => 'admin_process_models', :action=>'save_elem'

end

