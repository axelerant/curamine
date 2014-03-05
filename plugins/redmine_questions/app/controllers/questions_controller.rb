class QuestionsController < ApplicationController
  unloadable

  before_filter :find_optional_project, :only => [:autocomplete_for_topic, :topics]
  before_filter :find_optional_board, :only => [:autocomplete_for_topic, :topics]
  before_filter :find_topic, :authorize, :only => :vote
  before_filter :find_topics, :only => [:topics, :autocomplete_for_topic]

  helper :questions
  if Redmine::VERSION.to_s > '2.1'
    helper :boards
  end
  include QuestionsHelper

  def index
    @boards = Board.visible.includes(:last_message => :author).includes(:messages).order(:project_id).all
    # show the board if there is only one
    if @boards.size == 1
      @board = @boards.first  
      redirect_to project_board_url(@board, :project_id => @board.project)
    else  
      render "boards/index"
    end
  end

  def topics
  end

  def vote
    User.current.voted_for?(@topic) ? @topic.unvote(:voter => User.current.becomes(Principal)): @topic.vote(:voter => User.current.becomes(Principal))
    respond_to do |format|
      format.html { redirect_to_referer_or {render :text => (watching ? 'Vote added.' : 'Vote removed.'), :layout => true}}
    end    
  end

  def autocomplete_for_topic
    render :layout => false
  end

  def convert_issue
    issue = Issue.visible.find(params[:issue_id])
    board = Board.visible.find(params[:board_id])
    message = Message.new
    message.author = issue.author
    message.created_on = issue.created_on
    message.board = board
    message.subject = issue.subject
    message.content = issue.description.blank? ? issue.subject : issue.description
    message.watchers = issue.watchers
    message.add_watcher(issue.author)
    message.attachments = issue.attachments
    issue.journals.select{|j| !j.notes.blank?}.each do |journal|
      reply = Message.new
      reply.author = journal.user
      reply.created_on = journal.created_on
      reply.subject = "Re: #{message.subject}"
      reply.content = journal.notes
      reply.board = board
      message.children << reply
    end
    if message.save
      issue.destroy if params[:destroy]
      redirect_to board_message_path(board, message)
    else
      redirect_back_or_default({:controller => 'issues', :action => 'show', :id => issue})
    end

  end

private

  def find_topics
    seach = params[:q] || params[:topic_search]

    columns = ["subject", "content"]
    tokens = seach.to_s.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect{|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}.uniq.select {|w| w.length > 1 }
    tokens = [] << tokens unless tokens.is_a?(Array)
    token_clauses = columns.collect {|column| "(LOWER(#{column}) LIKE ?)"}
    sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(' AND ')
    find_options = {}
    find_options[:conditions] = [sql, * (tokens.collect {|w| "%#{w.downcase}%"} * token_clauses.size).sort]

    scope = Message.scoped({}) 
    scope = scope.where("#{Message.table_name}.parent_id IS NULL")
    scope = scope.where(["#{Board.table_name}.project_id = ?", @project.id]) if @project
    scope = scope.where(["#{Message.table_name}.board_id = ?", @board.id]) if @board
    scope = scope.tagged_with(params[:tag]) unless params[:tag].blank?
    scope = scope.scoped(find_options) unless tokens.blank?

    scope = scope.visible.includes(:board).order("#{Message.table_name}.updated_on DESC")
    
    @topic_count = scope.count
    @limit =  per_page_option 
    @topic_pages = Paginator.new(self, @topic_count, @limit, params[:page])     
    @offset = @topic_pages.current.offset  
    scope = scope.scoped :limit  => @limit, :offset => @offset
    @topics = scope    
  end

  def find_topic
    @topic = Message.visible.find(params[:id]) unless params[:id].blank?
    @board = @topic.board
    @project = @board.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_board
    @board = Board.visible.find(params[:board_id]) unless params[:board_id].blank?
    @project = @board.project if @board
    allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end



end
