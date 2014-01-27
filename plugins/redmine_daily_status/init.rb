require 'redmine'

Redmine::Plugin.register :redmine_daily_status do
  name 'Daily Status'
  author 'Amol Pujari, Vishal Mene'
  description 'Consolidated Team Daily Status'
  version '0.0.1'
  url 'https://github.com/gs-lab/redmine_daily_status'
  author_url 'https://github.com/gs-lab/redmine_daily_status'

  project_module :daily_status do
    permission :view_daily_status,   :daily_statuses => :index
    permission :manage_daily_status, :daily_statuses => :save
  end
 
  menu :project_menu, :daily_statuses,
    { :controller => 'daily_statuses', :action => 'index' },
    :caption => :daily_status,
    :after => :activity,
    :param => :project_id
end
Redmine::Activity.map do |activity|
  activity.register :daily_statuses,{:class_name => 'DailyStatus'}
end
require_dependency 'daily_status_project_patch'
require 'daily_status_mailer'
