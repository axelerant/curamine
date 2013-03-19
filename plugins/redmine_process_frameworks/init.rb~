require 'redmine'

Redmine::Plugin.register :redmine_process_frameworks do
  name 'Redmine Process Frameworks plugin'
  author 'Jianqiang.guo Jie.li Meng.yan'
  author_url 'mailto:geron_ever@sina.cn'   
  description 'Modelling the software process.'
  version '1.0.1'
  url 'http://example.com/path/to/plugin'


  project_module :process_frameworks do
      permission :label_view_process_framework, {:init_select => [:select_models,:select_activities,:view_process_framework,
      :export_process_framework,:show_details,:save_process_framework,:remove_model]}
      permission :label_import_process_framework, {:init_select => [:import_process_framework]}
  end
      menu :project_menu, :process_frameworks, { :controller => 'init_select', :action => 'select_models' },
             :caption => :project_module_process_frameworks,:last => true,:param => :project_id
      menu :admin_menu, :process_frameworks, {:controller => 'admin_process_models', :action => 'index'}, :class => 'issue_statuses', :caption => :project_module_process_frameworks
end
