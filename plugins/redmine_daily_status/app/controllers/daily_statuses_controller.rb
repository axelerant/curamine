class DailyStatusesController < ApplicationController
  unloadable
  
  before_filter :find_project, :authorize
  #helper :watchers
  #include WatchersHelper

  def index
    @todays_status = @project.todays_status

    days_ago = params[:days_ago].nil? ? nil : params[:days_ago].to_s.to_i

    if !params[:day].blank?
      begin
        Date.parse(params[:day])
      rescue
       #flash.now[:notice] = l(:label_invalid_date_format)
       days_ago = 0
      end
    end

    days_ago ||= ((Time.now - params[:day].to_s.to_datetime)/1.day).to_i unless params[:day].blank?

    days_ago ||= 0

    if days_ago > 0
      @daily_status = DailyStatus.ago days_ago, @project.id
      flash.now[:notice] = l(:label_last_status_not_available, :days => days_ago) unless @daily_status
    end

    @daily_status ||= @todays_status
    @daily_status ||= @project.daily_statuses.build
  end

  def save
    @todays_status = @project.todays_status || @project.daily_statuses.build

    params[:daily_status][:author_id] = User.current.id # current user id

    if @todays_status.update_attributes params[:daily_status]
      flash[:notice] = l(:label_status_saved)

      if !params[:daily_status][:is_email_sent].nil? and @todays_status.email
        flash[:notice] << l(:label_email_sent_to_all_members)
      end

    else
      flash[:notice] = @todays_status.errors.full_messages.first

    end
    
    #render :index
    redirect_to({ :action => 'index'});
  end

  private

  def find_project
    #id = params[:project_id].to_s.to_i
    #return @project = Project.where(:id => params[:project_id]).first if id > 0
    return @project = Project.where(:identifier => params[:project_id]).first
  end
end
