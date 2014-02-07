class HelpdeskReportsController < ApplicationController
  unloadable
  menu_item :issues
  before_filter :find_optional_project, :authorize_global

  def index
  end

  def staff_report
  end

  def tickets_report
    retrieve_date_range
    @helpdesk_tickets = (@project ? HelpdeskTicket.where(:projects => {:id => @project}) : HelpdeskTicket).includes(:issue => [:project]).where(@where_ticket)
    @helpdesk_messages = (@project ? JournalMessage.where(:projects => {:id => @project}) : JournalMessage).includes(:journal => {:issue => [:project]}).where(:is_incoming => false).where(@where_reply)
    @customers = (@project ? Contact.where(:projects => {:id => @project}) : Contact).includes(:tickets => :project).where(@where_contact)

    avg_response_time
    avg_close_time
  end

private

  def avg_response_time
    min_date_message =  ActiveRecord::Base.connection.select_all(
      "SELECT MIN(journal_messages.message_date) AS min_date, helpdesk_tickets.ticket_date, issues.id 
      FROM journal_messages
      INNER JOIN journals ON journals.id = journal_messages.journal_id 
      INNER JOIN issues ON issues.id = journals.journalized_id 
      INNER JOIN helpdesk_tickets ON issues.id = helpdesk_tickets.issue_id  
      INNER JOIN projects ON projects.id = issues.project_id 
      WHERE 
        #{@where_project} 
        AND #{@where_ticket}
      GROUP BY issues.id, helpdesk_tickets.ticket_date")

    if min_date_message.any?
      seconds = min_date_message.map{|d| (d["min_date"].to_time - d["ticket_date"].to_time)/1.second }.sort
      len = seconds.length
      median = len % 2 == 1 ? seconds[len/2] : (seconds[len/2 - 1] + seconds[len/2]).to_f / 2
      average = (seconds[0] + seconds[len - 1]).to_f / 2


      @avg_response_time = "#{format_time_period(average)[0].to_i} days, #{'%02d' % format_time_period(average)[1].to_i}:#{'%02d' % format_time_period(average)[2].to_i}:#{'%02d' % format_time_period(average)[3].to_i}"
      @median_response_time = "#{format_time_period(median)[0].to_i} days, #{'%02d' % format_time_period(median)[1].to_i}:#{'%02d' % format_time_period(median)[2].to_i}:#{'%02d' % format_time_period(median)[3].to_i}"
    else
      0
    end  
  end

  def avg_close_time
    max_close_date_issues =  ActiveRecord::Base.connection.select_all(
      "SELECT MIN(journals.created_on) AS close_date, helpdesk_tickets.ticket_date, issues.id 
      FROM journals
      INNER JOIN journal_details ON journals.id = journal_details.journal_id 
      INNER JOIN issues ON issues.id = journals.journalized_id 
      INNER JOIN helpdesk_tickets ON helpdesk_tickets.issue_id = issues.id 
      INNER JOIN projects ON projects.id = issues.project_id 
      WHERE 
        #{@where_project} 
        AND journal_details.prop_key = 'status_id'
        AND journal_details.value IN (SELECT issue_statuses.id FROM issue_statuses WHERE issue_statuses.is_closed = #{ActiveRecord::Base.connection.quoted_true})
        AND #{@where_ticket}
      GROUP BY issues.id, helpdesk_tickets.ticket_date")

    if max_close_date_issues.any?
      seconds = max_close_date_issues.map{|d| (d["close_date"].to_time - d["ticket_date"].to_time)/1.second }.sort
      len = seconds.length
      median = len % 2 == 1 ? seconds[len/2] : (seconds[len/2 - 1] + seconds[len/2]).to_f / 2
      average = (seconds[0] + seconds[len - 1]).to_f / 2

      @avg_close_time = "#{format_time_period(average)[0].to_i} days, #{'%02d' % format_time_period(average)[1].to_i}:#{'%02d' % format_time_period(average)[2].to_i}:#{'%02d' % format_time_period(average)[3].to_i}"
      @median_close_time = "#{format_time_period(median)[0].to_i} days, #{'%02d' % format_time_period(median)[1].to_i}:#{'%02d' % format_time_period(median)[2].to_i}:#{'%02d' % format_time_period(median)[3].to_i}"
    else
      0
    end
  end

  # def date_clause(table, field, from, to)
  #   s = []
  #   if from
  #     from_yesterday = from - 1
  #     from_yesterday_time = Time.local(from_yesterday.year, from_yesterday.month, from_yesterday.day)
  #     if self.class.default_timezone == :utc
  #       from_yesterday_time = from_yesterday_time.utc
  #     end
  #     s << ("#{table}.#{field} > '%s'" % [connection.quoted_date(from_yesterday_time.end_of_day)])
  #   end
  #   if to
  #     to_time = Time.local(to.year, to.month, to.day)
  #     if self.class.default_timezone == :utc
  #       to_time = to_time.utc
  #     end
  #     s << ("#{table}.#{field} <= '%s'" % [connection.quoted_date(to_time.end_of_day)])
  #   end
  #   s.join(' AND ')
  # end

  def retrieve_date_range
    @where_project = @project ? "projects.id = #{@project.id}" : "(1=1)"

    @free_period = false
    @from, @to = nil, nil

    if params[:period_type] == '1' || (params[:period_type].nil? && !params[:period].nil?)
      case params[:period].to_s
      when 'today'
        @from = @to = Date.today
      when 'yesterday'
        @from = @to = Date.today - 1
      when 'current_week'
        @from = Date.today - (Date.today.cwday - 1)%7
        @to = @from + 6
      when 'last_week'
        @from = Date.today - 7 - (Date.today.cwday - 1)%7
        @to = @from + 6
      when '7_days'
        @from = Date.today - 7
        @to = Date.today
      when 'current_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1)
        @to = (@from >> 1) - 1
      when 'last_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
        @to = (@from >> 1) - 1
      when '30_days'
        @from = Date.today - 30
        @to = Date.today
      when 'current_year'
        @from = Date.civil(Date.today.year, 1, 1)
        @to = Date.civil(Date.today.year, 12, 31)
      end
    elsif params[:period_type] == '2' || (params[:period_type].nil? && (!params[:from].nil? || !params[:to].nil?))
      begin; @from = params[:from].to_s.to_date unless params[:from].blank?; rescue; end
      begin; @to = params[:to].to_s.to_date unless params[:to].blank?; rescue; end
      @free_period = true
    else
      # default
    end

    @from, @to = @to, @from if @from && @to && @from > @to

    from_yesterday_time = (Time.local(@from.year, @from.month, @from.day) - 1).end_of_day if @from
    to_time = Time.local(@to.year, @to.month, @to.day).end_of_day if @to

    @where_ticket = if @from && @to
     "(#{HelpdeskTicket.table_name}.ticket_date BETWEEN '%s' AND '%s')" % [ActiveRecord::Base.connection.quoted_date(from_yesterday_time), ActiveRecord::Base.connection.quoted_date(to_time)]
    elsif @from
     "(#{HelpdeskTicket.table_name}.ticket_date > '%s')" % [ActiveRecord::Base.connection.quoted_date(from_yesterday_time)]
    elsif @to
     "(#{HelpdeskTicket.table_name}.ticket_date <= '%s')" % [ActiveRecord::Base.connection.quoted_date(to_time)]
    else
     "(1=1)"
    end    

    @where_reply = if @from && @to
     "(#{JournalMessage.table_name}.message_date BETWEEN '%s' AND '%s')" % [ActiveRecord::Base.connection.quoted_date(from_yesterday_time), ActiveRecord::Base.connection.quoted_date(to_time)]
    elsif @from
     "(#{JournalMessage.table_name}.message_date > '%s')" % [ActiveRecord::Base.connection.quoted_date(from_yesterday_time)]
    elsif @to
     "(#{JournalMessage.table_name}.message_date <= '%s')" % [ActiveRecord::Base.connection.quoted_date(to_time)]
    else
     "(1=1)"
    end  

    @where_contact = if @from && @to
     "(#{Contact.table_name}.created_on BETWEEN '%s' AND '%s')" % [ActiveRecord::Base.connection.quoted_date(from_yesterday_time), ActiveRecord::Base.connection.quoted_date(to_time)]
    elsif @from
     "(#{Contact.table_name}.created_on > '%s')" % [ActiveRecord::Base.connection.quoted_date(from_yesterday_time)]
    elsif @to
     "(#{Contact.table_name}.created_on <= '%s')" % [ActiveRecord::Base.connection.quoted_date(to_time)]
    else
     "(1=1)"
    end  


  end  

  def format_time_period(time_period)
      seconds    =  time_period % 60
      time_period = (time_period - seconds) / 60
      minutes    =  time_period % 60
      time_period = (time_period - minutes) / 60
      hours      =  time_period % 24
      time_period = (time_period - hours)   / 24
      days       =  time_period % 7
      weeks      = (time_period - days)    /  7
      [days, hours, minutes, seconds]    
  end

  def issue_time_to_close(issue)
    closed_journal_detail = JournalDetail.includes(:journal => :issue).where(:issues => {:id => issue.id}).where(:prop_key => 'status_id', :value => IssueStatus.where(:is_closed => true)).last    
    if closed_journal_detail
      closed_journal = closed_journal_detail.journal 
      closed_journal.created_on - closed_journal.issue.helpdesk_ticket.ticket_date
    else
      nil
    end
  end

end
