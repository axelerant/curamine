class FavouriteProjectsController < ApplicationController
  unloadable

  def index
    @favourite_projects = FavouriteProject.find(:all,:conditions => ["user_id = ?", User.current.id],:include => :project, :order => 'projects.name')
    @available_projects = Project.find_by_sql("select projects.* FROM projects, members WHERE project_id = projects.id and user_id = '#{User.current.id}' and project_id NOT IN (select project_id from favourite_projects where user_id = '#{User.current.id}') order by projects.name")
  end
  
  def add_project
    @project = FavouriteProject.new
    @project.project_id = params[:id]
    @project.user_id = User.current.id
    if request.post?
      if @project.save then
	flash[:notice] = l('favourite_projects.controllers.add_project_notice')
        redirect_to :controller => 'favourite_projects', :action => 'index'
      end
    end
  end

  def remove_project
    FavouriteProject.destroy(params[:id])
    redirect_to :controller => 'favourite_projects', :action => 'index'
  end
  
end
