class CannedResponsesController < ApplicationController
  unloadable

  before_filter :find_canned_response, :except => [:new, :create, :index]
  before_filter :find_optional_project, :only => [:new, :create, :add, :destroy]
  before_filter :find_issue, :only => [:add]

  accept_api_auth :index


  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    @canned_response_count = CannedResponse.visible.count
    @canned_response_pages = Paginator.new @canned_response_count, @limit, params['page']
    @canned_responses = CannedResponse.visible.all(:limit => @limit, :offset => @offset, :order => "#{CannedResponse.table_name}.name")

    respond_to do |format|
      format.api
    end
  end

  def add
    @content = HelpdeskMailer.apply_macro(@canned_response.content, @issue.customer, @issue, User.current) 
  end

  def new
    @canned_response = CannedResponse.new
    @canned_response.user = User.current
    @canned_response.project = @project
    @canned_response.is_public = false unless User.current.allowed_to?(:manage_public_canned_responses, @project) || User.current.admin?
  end

  def create
    @canned_response = CannedResponse.new(params[:canned_response])
    @canned_response.user = User.current
    @canned_response.project = params[:canned_response_is_for_all] ? nil : @project
    @canned_response.is_public = false unless User.current.allowed_to?(:manage_public_canned_responses, @project) || User.current.admin?

    if @canned_response.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to settings_project_path(@project, :tab => 'helpdesk_canned_responses')
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    @canned_response.attributes = params[:canned_response]
    @canned_response.project = nil if params[:canned_response_is_for_all]
    @canned_response.is_public = false unless User.current.allowed_to?(:manage_public_canned_responses, @project) || User.current.admin?

    if @canned_response.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to settings_project_path(@project, :tab => 'helpdesk_canned_responses')
    else
      render :action => 'edit'
    end
  end

  def destroy
    @canned_response.destroy
    redirect_to settings_project_path(@project, :tab => 'helpdesk_canned_responses')
  end

private
  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404    
  end

  def find_canned_response
    @canned_response = CannedResponse.find(params[:id])
    @project = @canned_response.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
