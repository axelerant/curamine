gem "actionmailer"
require "mailer"

class DailyStatusMailer < Mailer
  unloadable
  ActionMailer::Base.prepend_view_path(File.join(File.dirname(__FILE__), '../app/views'))

  include Redmine::I18n

  def send_daily_status( daily_status, recipients)
  	print recipients
    @project_name = daily_status.project.name
    @daily_status_content = daily_status.content
    @login_user_name = User.current.name;
    mail(:to => recipients, :subject => "#{l(:label_email_subject)} #{@project_name}", :content_type => "text/html")
  end
end
