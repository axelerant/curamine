# -*- coding: utf-8 -*-
class AdminProcessModelsController < ApplicationController

  unloadable

  layout 'admin'
  before_filter :require_admin
  def index
    @tab = params[:tab] || 'ProcessModel'

    model_pages,model_list = paginate :process_models, :per_page => 2000, :order => "position"
    activity_pages, activity_list = paginate :activities, :per_page => 2000, :order => "position"
    action_pages, action_list = paginate :actions, :per_page => 2000, :order => "position"
    task_pages, task_list = paginate :pf_tasks, :per_page => 2000, :order => "position"


    @all_lists = {"ProcessModel" => model_list,"Activity" =>activity_list,"Action" =>action_list,"PfTask"=>task_list}
    @all_pages = {"ProcessModel" => model_pages,"Activity" =>activity_pages,"Action" =>action_pages,"PfTask"=>task_pages}
  end


  def show_subs
    @parent_id  = params[:parent_id]
    elem = eval(params[:parent_type]).find(@parent_id)
    get_subs_name(elem,@parent_id)
    if @subs.nil?
      puts "subs is nil"
      return
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @subs}
      format.xml { render :xml => @type_name}
      format.xml { render :xml => @empty_subs}
      format.xml { render :xml => @parent_id}
    end
  end

  def open_close_model
    model = ProcessModel.find(params[:elem])
    if model.position==0
      position_model = ProcessModel.find(:first, :order=> "position DESC")
      model.position = position_model.nil?? 1: (position_model.position+1)
    else
      model.position = -model.position
    end
    model.update_attributes(model.attributes)

    redirect_to  :controller => 'admin_process_models',:action => 'index', :tab =>'ProcessModel'
  end

  def sort_model
    model = ProcessModel.find(params[:id])
    if request.post? and  model.update_attributes(params[:process_model])
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:notice] = "failed!"
      return
    end
    redirect_to :action => 'index', :tab =>'ProcessModel'
  end

  def sort_elem
    elem = eval(params[:type]).find(params[:elem])
    if request.post? and  elem.update_attributes(params[:"#{params[:type].downcase}s"])
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:notice] = "failed!"
      return
    end
    redirect_to :action => 'show_subs', :parent_id =>params[:parent_id], :parent_type => eval(params[:type]).get_parent_name
  end

  # link to a page new elem
  def new_elem
    @type_name =  params[:type]
    @name =eval(@type_name).to_p_name
    @parent_id = params[:parent_id]
  end

  #save a elem into database, not relationship
  def save_elem
    type = params[:type_name]

    parent_id = params[:parent_id].nil?? -1:params[:parent_id]

    if request.post? and  elem = eval(type).new(params[:type])
      case type
      when "ProcessModel"
        elem.date = Time.now
        elem.author_id = User.current.id
      when "Activity"
      elem.model_id =  parent_id
      when "Action"
      elem.activity_id =  parent_id
      when "PfTask"
      elem.action_id =  parent_id
      end
      elem.save
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:notice] = "failed!"
      return
    end
    if parent_id==-1
      redirect_to :action => 'index', :tab =>params[:type_name]
    else
      redirect_to :action =>'show_subs',:parent_id => parent_id, :parent_type => elem.class.get_parent_name
    end
  end

  #add element to parent elem(relaition)
   def add_elem
    type = params[:type]
    parent_type =eval(type).get_parent_name
    select_id = params[:select][:select_id]
    if  select_id.nil? || select_id == ""
      flash[:error] =l(:label_please_select)+eval(type).to_p_name
      redirect_to :action => 'show_subs', :parent_id =>params[:parent_id], :parent_type => parent_type
      return
    end
     elem = eval(type).find(select_id)
      case type
        when "Activity"
        elem.model_id = params[:parent_id]
        when "Action"
        elem.activity_id = params[:parent_id]
        when "PfTask"
        elem.action_id = params[:parent_id]
      end
      position_elem= eval(type).find(:first, :order=> "position DESC")
      elem.position = position_elem.nil?? 1: (position_elem.position+1)
      elem.update_attributes(elem.attributes)
    redirect_to :action => 'show_subs', :parent_id =>params[:parent_id], :parent_type => parent_type

  end

  #delete element, include record in database
  def delete_elem
    elem = eval(params[:type]).find(params[:elem])
    eval(params[:type]).delete(params[:elem])
    elems = nil
     case params[:type]
        when "ProcessModel"
       elems = elem.activities
       for e in elems
         e.model_id =-1
         e.update_attributes(e.attributes)
       end
      when "Activity"
       elems = elem.actions
       for e in elems
         e.activity_id =-1
         e.update_attributes(e.attributes)
       end
      when "Action"
       elems = elem.pf_tasks
        for e in elems
         e.action_id =-1
         e.update_attributes(e.attributes)
       end
    end
    redirect_to :action => 'index', :tab =>params[:type]
  rescue
    flash[:error] = l(:error_can_not_delete_custom_field)
    redirect_to :action => 'index',:tab =>params[:type]
  end


  #remoce elem ,only relationship
  def remove_elem
    elem =eval(params[:type]).find(params[:elem])
    elem.position= 0
    case params[:type]
      when "Activity"
      elem.model_id =  -1
      when "Action"
      elem.activity_id = -1
      when 'PfTask'
      elem.action_id = -1
    end
    elem.update_attributes(elem.attributes)
    redirect_to :action => 'show_subs', :parent_id =>params[:parent_id], :parent_type =>eval(params[:type]).get_parent_name
  end

  #get data from database
  def show_details
    @type = params[:type]
    @elem= eval(@type).find(params[:elem])
  end

  def update_elem
    type = params[:type]
    @elem = eval(type).find(params[:elem])

    if @elem.update_attributes(params["attrs"])
      flash[:notice] = "Updated successfully"
    else
      flash[:error] = "Failed to update! Try again or report to Redmine admin."
    end

    redirect_to :action => :index, :tab => type
  end

  private
  #get parent's all subs   id is parent_is,elem is a parent
   def get_subs_name(elem,id)
    @subs =nil
    @empty_subs =nil
    @type_name =nil
    case elem
      when ProcessModel
      @subs = Activity.find(:all,:conditions =>"model_id = #{id} " ,:order=> "position ASC")
      @empty_subs = Activity.find(:all, :conditions =>" model_id is null or model_id = -1 ")
      when Activity
      @subs = Action.find(:all, :conditions =>"activity_id = #{id} " ,:order=> "position ASC")
      @empty_subs = Action.find(:all, :conditions =>" activity_id is null or activity_id = -1 ")
      when Action
      @subs =PfTask.find(:all, :conditions =>"action_id = #{id} " ,:order=> "position ASC")
      @empty_subs =PfTask.find(:all, :conditions =>" action_id is null or action_id = -1 ")
    end
     @type_name =[elem.class.to_p_name,elem.name, elem.class.name]
  end


end
