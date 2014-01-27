# -*- coding: utf-8 -*-

class InitSelectController < ApplicationController
   unloadable   #向上兼容不同版本的  rails
   
  helper :gantt
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  require 'rexml/document'
  require 'iconv'
  
  #menu authority
  before_filter :find_project, :authorize, :all => true
  menu_item :process_frameworks,:all => true           
  
  
  #select model 
  def select_models
    @process_models =  ProcessModel.all
    
    respond_to do |format|
      format.html  #index.html.erb
      format.xml { render :xml => @process_models}
    end
  end
  
  #select activities
  def select_activities
    selected_model= params[:selected_model]
    if selected_model.nil? then
      flash[:error] = l(:label_warning_select_pro_model)
      redirect_to :controller=>'init_select',:action=>'select_models',:project_id => @project
      return
    else
      @selected_model = ProcessModel.find(selected_model)
      @activi_model_list = @selected_model.activities
      respond_to do |format|
        format.html  #show_activities.html.erb
        format.xml { render :xml => @activi_model_list} 
      end
    end
  end
  
  
  #add the process framework to the project
  def save_process_framework
    
    #project update model
    remove_model_help(@project)
    @project.model_id = params[:selected_model]
    @project.if_config_pf = true
    @project.save
    default_settings = Setting.plugin_redmine_process_frameworks
    #activities_save
    sys_activities = ProcessModel.find(@project.model_id).activities
    sys_activities.each do |a|
      if params[:"activity_#{a.id}"]=="yes" then
        ver = Version.find(:first,:conditions=>["name=? and project_id=?",a.name,@project.id])
        if ver.nil?  # not exsits:save
           activities_version_save(a)
          ver = Version.find(:first,:conditions=>["name=? and project_id=?",a.name,@project.id])
        else        #else update
          ver.save
        end
        #actions_save     
        sys_actions = a.actions    
        sys_actions.each do |ac|        
          if params[:"action_#{ac.id}"]=="yes" then
            act = Issue.find(:first,:conditions=>["subject=? and fixed_version_id=?",ac.name,ver.id])
            if act.nil?
              actions_issue_save(ac,ver.id, default_settings) 
              act = Issue.find(:first,:conditions=>["subject=? and fixed_version_id=?",ac.name,ver.id])
            else
              act.author_id   = User.current.id
              act.save
            end
            #tasks_save
            sys_tasks=ac.pf_tasks
            sys_tasks.each do |t|
              if params[:"task_#{t.id}"]=="yes" then
                ta = Issue.find(:first,:conditions=>["subject=? and parent_id=?",t.name,act.id])
                if ta.nil?
                  tasks_issue_save(t,ver.id,act.id, default_settings) 
                  ta = Issue.find(:first,:conditions=>["subject=? and parent_id=?",t.name,act.id])
                else
                  ta.author_id = User.current.id
                  ta.save
                end
              end
            end
          end
        end
      end
    end     
    redirect_to :controller=>'init_select',:action=>'view_process_framework',:project_id => @project     
  end
  
  
  #remvove a process model from the project
  def remove_model
   remove_model_help(@project)
   redirect_to  :controller=>'init_select',:action=>"select_models",:project_id => @project
  end
  
  #view process framework of the project
  def view_process_framework
    @gantt = Redmine::Helpers::Gantt.new(params)
    @gantt.project = @project
    retrieve_query
    @query.group_by = nil
    @gantt.query = @query if @query.valid?
    respond_to do |format|
      format.html  
      format.xml { render :xml => @gantt}
    end
  end
  
  #export the process of the project to XML file
  def export_process_framework
    @gantt = Redmine::Helpers::Gantt.new(params)
    @gantt.project = @project
    retrieve_query
    @query.group_by = nil
    @gantt.query = @query if @query.valid?
    
    @versions = Version.find(:all, :conditions => ["project_id = ?",@project.id], :order => 'effective_date ASC')
    doc = REXML::Document.new 
    doc << REXML::XMLDecl.new('1.0', 'UTF-8') 
    temp_model = ProcessModel.new
    temp_model.id=0;
    if @project.if_config_pf
      temp_model= ProcessModel.find(@project.model_id)
    end
    filename = params[:filename].to_s
    if filename.empty?
      flash[:error] = l(:label_model_name)+l(:label_cann_blank)
      redirect_to :controller=>'init_select',:action=>'view_process_framework',:project_id => @project
      return
    end
    
    process_model=doc.add_element('process_model',{'name'=>filename})#"2"Ҫ��Ϊ@project.model_id
    process_model.add_text(params[:file_desc])
    @versions.each do |ver|                           
      issues = Issue.find(:all, :conditions => ["project_id=? and fixed_version_id=?",@project.id,ver.id])
      activity = process_model.add_element('activity',{'name'=>ver.name})
      activity.add_text(ver.description) 
      issues.each do |issue|               
        if issue.parent_id.nil?
          action = activity.add_element('action',{'name'=>issue.subject})  
          action.add_text(issue.description)
          if issue.children?
            issue.children.each do |child|
              task = action.add_element('task',{'name'=>child.subject})  
              task.add_text(child.description)
            end
        end
       end
      end
    end
    doc.write()
    filename = Iconv.iconv("UTF-8", "UTF-8", filename) 
    send_data(doc.to_s, :filename => filename.to_s+".xml" , :disposition => 'attachment')
  end
  
  #import  XML file as the process of the project 
  def import_process_framework
    uploaded_file = params[:xml_file]
    unless uploaded_file.nil?
      orig_name = uploaded_file.original_filename
      if File.extname(orig_name).downcase == ".xml" 
        data = uploaded_file.read if uploaded_file.respond_to? :read
        doc = REXML::Document.new( data )
       position_model = ProcessModel.find(:first, :order=> "position DESC")
       model_position = position_model.nil?? 1: (position_model.position+1) 
        doc.elements.each("process_model") do |e| 
          if ProcessModel.find_by_name(e.attributes["name"]).nil?         
            new_process_model = ProcessModel.new
            new_process_model.name = e.attributes["name"]
            new_process_model.author_id = User.current.id
            new_process_model.date = Time.now
            new_process_model.description = e.text
            new_process_model.position = model_position
            new_process_model.save
            ++ model_position
            activies = e.get_elements("activity")
            activity_position =1
            activies.each do |acty|
              new_activity = Activity.new
              new_activity.name = acty.attributes["name"]
              new_activity.description = acty.text
              new_activity.model_id = new_process_model.id
              new_activity.position= activity_position
              ++activity_position
              new_activity.save
              action_position = 1
              actions = acty.get_elements("action")
              actions.each do |acns|
                new_action = Action.new
                new_action.name = acns.attributes["name"]
                new_action.description = acns.text
                new_action.activity_id = new_activity.id
                new_action.position = action_position
                new_action.save
                ++action_position 
                task_position = 1
                tasks = acns.get_elements("task")
                tasks.each do |task|
                  new_task = PfTask.new
                  new_task.name = task.attributes["name"]
                  new_task.description = task.text
                  new_task.action_id = new_action.id
                  new_task.position = task_position
                  ++task_position
                  new_task.save
                end
              end
            end
            
          else     
            flash[:error] = l(:lable_model_already_exist)
            redirect_to :controller=>'init_select',:action=>'select_models',:project_id => @project
            return
          end
        end    
        flash[:notice] = l(:lable_import_successfully)
        redirect_to :controller=>'init_select',:action=>'select_models',:project_id => @project
        return
      else
        flash[:error] = l(:lable_import_unsuccessfully)
        redirect_to :controller=>'init_select',:action=>'select_models',:project_id => @project
        return
      end
    else
      flash[:error] = l(:lable_please_select_file_first)
      redirect_to :controller=>'init_select',:action=>'select_models',:project_id => @project
      return
    end
  end
  
  #show elements's(action,task,activity) details
  def show_details
    @plat = eval(params[:name]).find(params[:plat])
    render :partial => "show_details"
  end
  
  private
  # model_save
  #version_save
  def activities_version_save(activity)
      ver = Version.new
      ver.project_id = @project.id
      ver.name = activity.name
      ver.description = activity.description
      version = Version.find(:first, :conditions => ["project_id = ?",@project.id], :order => 'effective_date DESC')
      if version.nil? or version.effective_date.blank?
         tmp_date = Time.now.advance(:days => 7)
      else
         tmp_date =version.effective_date.advance(:days => 7)
      end
      ver.effective_date  = Date.new(tmp_date.year, tmp_date.month, tmp_date.day)
      ver.if_pf = true
      ver.status  = "open"
      ver.save
  end
  
  
  #ac_issue_save 
  def actions_issue_save  (action,version_id, default_settings)
    ac_issue=Issue.new        
    ac_issue.subject=action.name
    ac_issue.description=action.description
    ac_issue.priority_id = default_settings['issue_default_priority'] || 4
    ac_issue.status_id = default_settings['issue_default_status'] || 1
    ac_issue.tracker_id = default_settings['issue_default_tracker'] || 3
    ac_issue.project_id = @project.id   
    ac_issue.fixed_version_id=version_id
    ac_issue.author_id = User.current.id   
    ac_issue.if_pf = true
    ac_issue.save
  end    

  #sub_issue_save
  def tasks_issue_save  (task,version_id,parent_id, default_settings)
    sub_issue=Issue.new                
    sub_issue.subject=task.name
    sub_issue.description=task.description 
    sub_issue.priority_id = default_settings['sub_issue_default_priority'] || 4
    sub_issue.status_id = default_settings['sub_issue_default_status'] || 1
    sub_issue.tracker_id = default_settings['sub_issue_default_tracker'] || 3
    sub_issue.parent_issue_id=parent_id                  
    sub_issue.project_id=@project.id
    sub_issue.fixed_version_id=version_id
    sub_issue.author_id = User.current.id
    sub_issue.if_pf = true
    sub_issue.save    
  end 
  def remove_model_help(project)
     rm_versions = project.versions
    rm_issues = project.issues
    rm_issues.each do |rm_issue| 
      if(rm_issue.if_pf)
        Issue.delete(rm_issue.id)
      end
    end
    rm_versions.each do |rm_version| 
      if(rm_version.if_pf)
        Version.delete(rm_version.id)
      end
    end
    project.model_id =nil
    project.if_config_pf=false
    
    project.save
  end
  
  def find_project
    @project = Project.find(params[:project_id])if params[:project_id]
  end
  
end
