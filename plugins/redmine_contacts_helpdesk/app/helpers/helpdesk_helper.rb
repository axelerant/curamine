module HelpdeskHelper
  def helpdesk_ticket_source_icon(helpdesk_ticket)
    case helpdesk_ticket.source
    when HelpdeskTicket::HELPDESK_EMAIL_SOURCE
      "icon-email"
    when HelpdeskTicket::HELPDESK_PHONE_SOURCE
      "icon-call"
    when HelpdeskTicket::HELPDESK_WEB_SOURCE
      "icon-web"
    when HelpdeskTicket::HELPDESK_TWITTER_SOURCE
      "icon-twitter"
    else
      "icon-helpdesk"
    end
  end

  def helpdesk_tickets_source_for_select
    [[l(:label_helpdesk_tickets_email), HelpdeskTicket::HELPDESK_EMAIL_SOURCE.to_s], 
     [l(:label_helpdesk_tickets_phone), HelpdeskTicket::HELPDESK_PHONE_SOURCE.to_s], 
     [l(:label_helpdesk_tickets_web), HelpdeskTicket::HELPDESK_WEB_SOURCE.to_s],
     [l(:label_helpdesk_tickets_conversation), HelpdeskTicket::HELPDESK_CONVERSATION_SOURCE.to_s]
    ]
    
  end
end
