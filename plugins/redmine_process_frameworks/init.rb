require 'redmine'

Redmine::Plugin.register :redmine_process_frameworks do
  name 'Redmine Process Frameworks plugin'
  author 'Jianqiang.guo Jie.li Meng.yan'
  author_url 'mailto:geron_ever@sina.cn'   
  description 'Modelling the software process.'
  version '1.2'
  url 'http://example.com/path/to/plugin'

  settings :default => {'issue_default_tracker' => '3', 'issue_default_priority' => '4', 'issue_default_status' => '1', 'sub_issue_default_tracker' => '3', 'sub_issue_default_priority' => '4', 'sub_issue_default_status' => '1'}, :partial => 'admin_process_models/configure_partial_redmine_framework'

  project_module :process_frameworks do
      permission :label_view_process_framework, {:init_select => [:select_models,:select_activities,:view_process_framework,
      :export_process_framework,:show_details,:save_process_framework,:remove_model]}
      permission :label_import_process_framework, {:init_select => [:import_process_framework]}
  end
      menu :project_menu, :process_frameworks, { :controller => 'init_select', :action => 'select_models' },
             :caption => :project_module_process_frameworks,:last => true,:param => :project_id
      menu :admin_menu, :process_frameworks, {:controller => 'admin_process_models', :action => 'index'}, :class => 'issue_statuses', :caption => :project_module_process_frameworks
end
