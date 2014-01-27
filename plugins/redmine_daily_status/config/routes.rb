get  '/projects/:project_id/daily_status'     => 'daily_statuses#index'
get  '/projects/:project_id/daily_status/:id' => 'daily_statuses#show',   :defaults => { :format => 'json' }
match '/projects/:project_id/daily_status_watchers/new', :to=>'daily_status_watchers#new', :via => :get
match '/projects/:project_id/daily_status_watchers', :to=>'daily_status_watchers#create', :via => :post
match '/projects/:project_id/daily_status_watchers/append', :to=>'daily_status_watchers#append', :via => :post
match '/projects/:project_id/daily_status_watchers/destroy', :to=> 'daily_status_watchers#destroy', :via => :post
match '/projects/:project_id/daily_status_watchers/watch', :to=> 'daily_status_watchers#watch', :via => :post
match '/projects/:project_id/daily_status_watchers/unwatch', :to=> 'daily_status_watchers#unwatch', :via => :post
match '/projects/:project_id/daily_status_watchers/autocomplete_for_user', :to=> 'daily_status_watchers#autocomplete_for_user', :via => :get
post '/projects/:project_id/daily_status'     => 'daily_statuses#save'


