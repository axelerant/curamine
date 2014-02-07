class HelpdeskTicketsController < ApplicationController
  unloadable

  before_filter :find_issue, :except => :destroy
  before_filter :find_helpdesk_ticket, :only => :destroy
  before_filter :authorize

  helper :helpdesk

  def edit
    @show_form = "true"    
    respond_to do |format|
      format.js
    end    
  end

  def update
    @helpdesk_ticket.attributes = params[:helpdesk_ticket]
    @helpdesk_ticket.issue = @issue
    @helpdesk_ticket.from_address = @helpdesk_ticket.customer.primary_email if @helpdesk_ticket.customer
    
    if @helpdesk_ticket.save
      flash[:notice] = l(:notice_successful_update) 
      respond_to do |format|
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', :id => @issue}) }
        format.api  { render_api_ok }
      end
    else
      flash[:error] = @helpdesk_ticket.errors.full_messages.flatten.join("\n")
      respond_to do |format|
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', :id => @issue}) }
        format.api  { render_validation_errors(@helpdesk_ticket) }
      end      
    end
  end

  def destroy  
    if @helpdesk_ticket.destroy
      flash[:notice] = l(:notice_successful_delete)
      respond_to do |format|
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', :id => @issue}) }
        format.api { render_api_ok }
      end      
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
  end  

private 
  def find_helpdesk_ticket
    @helpdesk_ticket = HelpdeskTicket.find(params[:id])
    @issue = @helpdesk_ticket.issue
    @project = @issue.project if @issue
  rescue ActiveRecord::RecordNotFound
    render_404    
  end

  def find_issue
    @issue = Issue.find(params[:issue_id]) 
    @project = @issue.project    
    @helpdesk_ticket = @issue.helpdesk_ticket || HelpdeskTicket.new(:ticket_date => Time.now, :issue => @issue)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
