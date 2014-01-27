require 'daily_status_mailer'
class DailyStatus < ActiveRecord::Base
  unloadable
  default_scope order('created_at desc')
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  validates_presence_of :content

  def setting
    project.daily_status_setting or project.create_daily_status_setting
  end

  acts_as_event :datetime => :created_at,
                :description => :content,
                :title => :content,
                :url =>Proc.new {
                                  |o|
                                  {
                                      :controller => 'daily_statuses',
                                      :action => 'index',
                                      :project_id => o.project ,
                                      :day => (o.created_at.to_date).to_s
                                  }
                                }

  acts_as_activity_provider :timestamp => "#{table_name}.created_at",
                            :find_options => {
                                                :include => [:project, :author],
                                                :select => "#{table_name}.*",
                                                :conditions => "#{table_name}.is_email_sent=true"
                                              },
                            :permission => :view_daily_status,
                            :author_key => :author_id
                            

  def email
    if !(setting.watcher_recipients).empty?
      recipients = setting.watcher_recipients
    else
      recipients = project.members.collect {|m| m.user}.collect(&:mail)      
    end  
    DailyStatusMailer.send_daily_status(self, recipients).deliver
  end

  def self.on time, project_id
    where(:project_id => project_id).where("DATE(created_at) = DATE(?)", time).first
  end

  def self.ago number_of, project_id
    #on Time.now-number_of.days, project_id
    on Date.today-number_of.days, project_id
  end

  def self.todays_status_for project
    where(:project_id => project.id).where("created_at >= ? and created_at <= ?", Date.today.beginning_of_day, Date.today.end_of_day).first
  end

end
