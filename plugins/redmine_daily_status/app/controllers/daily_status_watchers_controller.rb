class DailyStatusWatchersController < ApplicationController
    unloadable

  before_filter :find_project
  before_filter :require_login, :check_project_privacy, :only => [:watch, :unwatch]
  #before_filter :authorize, :only => [:new, :destroy]
  helper :DailyStatuses
  include DailyStatusesHelper

  def watch
    if @watched.respond_to?(:visible?) && !@watched.visible?(User.current)
      render_403
    else
      set_watcher(User.current, true)
    end
  end

  def unwatch
    set_watcher(User.current, false)
  end

  def new
    
  end

  def create
    if params[:watcher].is_a?(Hash) && request.post?
      user_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]]
      user_ids.each do |user_id|
        Watcher.create(:watchable => @watched, :user_id => user_id)
      end
    end
    respond_to do |format|
      format.html { redirect_to_referer_or {render :text => 'Watcher added.', :layout => true}}
      format.js
    end
  end

  def append
    if params[:watcher].is_a?(Hash)
      user_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]]
      @users = User.active.find_all_by_id(user_ids)
    end
  end

  def destroy
    @watched.set_watcher(User.find(params[:user_id]), false) if request.post?
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  def autocomplete_for_user
    @users = User.active.like(params[:q]).find(:all, :limit => 100)
    if @watched
      @users -= @watched.watcher_users
    end
    render :layout => false
  end

private
  def find_project
    if params[:object_type] && params[:object_id]
      klass = Object.const_get(params[:object_type].camelcase)
      return false unless klass.respond_to?('watched_by')
      @watched = klass.find(params[:object_id])
      @project = @watched.project
    elsif params[:project_id]
      @project = Project.visible.find_by_param(params[:project_id])
    end
  rescue
    render_404
  end

  def set_watcher(user, watching)
    @watched.set_watcher(user, watching)
    respond_to do |format|
      format.html { redirect_to_referer_or {render :text => (watching ? 'Watcher added.' : 'Watcher removed.'), :layout => true}}
      format.js { render :partial => 'set_watcher', :locals => {:user => user, :watched => @watched} }
    end
  end
end