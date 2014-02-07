class PublicTicketsController < ApplicationController
  unloadable
  layout 'public_tickets'

  skip_before_filter :check_if_login_required
  before_filter :find_ticket, :authorize_ticket

  helper :issues
  helper :attachments
  helper :journals
  helper :custom_fields

  def show
    @previous_tickets = @ticket.customer.tickets.includes([:status, :helpdesk_ticket]).order_by_status

    @total_spent_hours = @previous_tickets.map.sum(&:total_spent_hours)

    @journals = @issue.journals.includes(:user).includes(:details).order("#{Journal.table_name}.created_on ASC").where("EXISTS (SELECT * FROM #{JournalMessage.table_name} WHERE #{JournalMessage.table_name}.journal_id = #{Journal.table_name}.id)")
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @journal = @issue.journals.new

    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    prepend_view_path "app/views/issues"

  end

  def add_comment
    @journal = @issue.journals.new(params[:journal])
    @issue.status_id = HelpdeskSettings[:helpdesk_reopen_status,  @issue.project_id] unless HelpdeskSettings[:helpdesk_reopen_status,  @issue.project_id].blank?
    @journal.user = User.current
    @journal.journal_message = JournalMessage.new(:from_address => @ticket.customer_email,
                                                  :contact => @ticket.customer,
                                                  :journal => @journal,
                                                  :is_incoming => true,
                                                  :message_date => Time.now)
    if @journal.save
      flash[:notice] = l(:notice_successful_create)
      @issue.save
    end
    redirect_back_or_default(public_ticket_path(@ticket, @ticket.token))
  end

  def render_404(options={})
    @message = l(:notice_file_not_found)
    respond_to do |format|
      format.html {
        render :template => 'common/error', :status => 404
      }
      format.any { head 404 }
    end
    return false
  end


  private

  def find_ticket
    @ticket = HelpdeskTicket.find(params[:id])
    @issue = @ticket.issue
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_ticket(action = params[:action])
    allow = true
    allow &&= RedmineHelpdesk.public_comments? if (action.to_s == "add_comment")
    allow &&= (@ticket.token == params[:hash]) && RedmineHelpdesk.public_tickets?
    render_404 unless allow
  end

end