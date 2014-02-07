class HelpdeskMailer < MailHandler
  include HelpdeskMailerHelper

  attr_reader :contact, :user, :email

  def self.default_url_options
    { :host => Setting.host_name, :protocol => Setting.protocol }
  end

  def issue_response(contact, journal, params)
    headers['X-Redmine-Ticket-ID'] = journal.issue.id.to_s
    @email_header = self.class.apply_macro(HelpdeskSettings[:helpdesk_emails_header, journal.issue.project], contact, journal.issue, journal.user) unless HelpdeskSettings[:helpdesk_emails_header, journal.issue.project].blank?
    @email_footer = self.class.apply_macro(HelpdeskSettings[:helpdesk_emails_footer, journal.issue.project], contact, journal.issue, journal.user)  unless HelpdeskSettings[:helpdesk_emails_footer, journal.issue.project].blank?
    @email_body = self.class.apply_macro(journal.notes, contact, journal.issue, journal.user)

    raise MissingInformation.new("Contact #{contact.name} should have mail") if contact.email.blank?
    raise MissingInformation.new("Message shouldn't be blank") if @email_body.blank?

    subject_macro = self.class.apply_macro(HelpdeskSettings[:helpdesk_answer_subject, journal.issue.project], contact, journal.issue)
    subject_macro += " - [##{journal.issue.id}]" if !subject_macro.blank? && !subject_macro.include?("##{journal.issue.id}]")
    @email_stylesheet = HelpdeskSettings[:helpdesk_helpdesk_css, journal.issue.project].to_s.html_safe

    params[:attachments].each_value do |mail_attachment|
      if file = mail_attachment['file']
        file.rewind if file
        attachments[file.original_filename] = file.read
        file.rewind if file
      elsif token = mail_attachment['token']
        if token.to_s =~ /^(\d+)\.([0-9a-f]+)$/
          attachment_id, attachment_digest = $1, $2
          if a = Attachment.where(:id => attachment_id, :digest => attachment_digest).first
            attachments[a.filename] = File.read(a.diskfile)
          end
        end
      end
    end unless params[:attachments].blank?

    cc_address = (params[:helpdesk] && !params[:helpdesk][:cc_list].blank? && !params[:helpdesk][:is_cc].blank?) ? params[:helpdesk][:cc_list] : ""
    bcc_address = (params[:helpdesk] && !params[:helpdesk][:bcc_list].blank? && !params[:helpdesk][:is_cc].blank?) ? params[:helpdesk][:bcc_list] : ""
    in_reply_to = (journal.issue.helpdesk_ticket.blank? || journal.issue.helpdesk_ticket.message_id.blank?) ? '' : "<#{journal.issue.helpdesk_ticket.message_id}>"
    to_address = (params[:helpdesk] && !params[:helpdesk][:to_address].blank?) ? params[:helpdesk][:to_address] : contact.primary_email
    from_address = HelpdeskSettings[:helpdesk_answer_from, journal.issue.project].blank? ? Setting.mail_from : HelpdeskSettings[:helpdesk_answer_from, journal.issue.project]

    logger.error "Helpdesk MailHandler: from address couldn't be black" if from_address.blank? && logger && logger.error

    mail :from => from_address,
         :to => to_address,
         :cc => cc_address,
         :in_reply_to => in_reply_to,
         :bcc => bcc_address,
         :subject => subject_macro.blank? ? journal.issue.subject + " [#{journal.issue.tracker} ##{journal.issue.id}]" : subject_macro do |format|
      format.text { render 'email_layout' }
      format.html { render 'email_layout' } unless RedmineHelpdesk.settings[:plain_text_mail]
    end
  end

  def self.receive(email, options={})
    @@helpdesk_mailer_options = options.dup
    super email
  end

  # Processes incoming emails
  # Returns the created object (eg. an issue, a message) or false
  def receive(email)
    @email = email
    if !target_project.module_enabled?(:contacts) || !target_project.module_enabled?(:issue_tracking)
      logger.error "Helpdesk MailHandler: contacts and issues modules should be enable for #{target_project.name} project" if logger && logger.error
      return false
    end

    sender_email = email.from_addrs.first.to_s.strip
    # Ignore emails received from the application emission address to avoid hell cycles
    if sender_email.downcase == Setting.mail_from.to_s.strip.downcase
      logger.info  "Helpdesk MailHandler: ignoring email from Redmine emission address [#{sender_email}]" if logger && logger.info
      return false
    end

    self.class.ignored_emails_headers.each do |key, ignored_value|
      value = email.header[key]
      if value
        value = value.to_s.downcase
        if (ignored_value.is_a?(Regexp) && value.match(ignored_value)) || value == ignored_value
          if logger && logger.info
            logger.info "Helpdesk MailHandler: ignoring email with #{key}:#{value} header"
          end
          return false
        end
      end
    end

    if !check_blacklist?(email)
      logger.info "Helpdesk MailHandler: Email #{sender_email} ignored because in blacklist" if logger && logger.info
      return false
    end

    @user = (HelpdeskSettings[:helpdesk_assign_author, target_project].to_i > 0 && User.find_by_mail(sender_email)) || User.anonymous
    @contact = contact_from_email(email)
    User.current = @user
    if @contact
      logger.info "Helpdesk MailHandler: [#{@contact.name}] contact created/founded" if logger && logger.info
    else
      logger.error "Helpdesk MailHandler: could not create/found contact for [#{sender_email}]" if logger && logger.error
      return false
    end

    dispatch
  end

  def self.check_project(project_id)
    msg_count = 0
    unless Project.find_by_id(project_id).blank? || HelpdeskSettings[:helpdesk_protocol, project_id].blank?

      mail_options, options = self.get_mail_options(project_id)

      case mail_options[:protocol]
      when "pop3" then
        msg_count = RedmineContacts::Mailer.check_pop3(self, mail_options, options)
      when "imap" then
        msg_count = RedmineContacts::Mailer.check_imap(self, mail_options, options)
      end
    end

    msg_count
  end

  def self.get_mail_options(project_id)
    case HelpdeskSettings[:helpdesk_protocol, project_id]
    when "gmail"
      protocol = "imap"
      host = "imap.gmail.com"
      port = "993"
      ssl = "1"
    when "yahoo"
      protocol = "imap"
      host = "imap.mail.yahoo.com"
      port = "993"
      ssl = "1"
    when "yandex"
      protocol = "imap"
      host = "imap.yandex.ru"
      port = "993"
      ssl = "1"
    else
      protocol = HelpdeskSettings[:helpdesk_protocol, project_id]
      host = HelpdeskSettings[:helpdesk_host, project_id]
      port = HelpdeskSettings[:helpdesk_port, project_id]
      ssl =  HelpdeskSettings[:helpdesk_use_ssl, project_id] != "1" ? nil : "1"
    end

    mail_options  = {:protocol => protocol,
                    :host => host,
                    :port => port,
                    :ssl => ssl,
                    :apop => HelpdeskSettings[:helpdesk_apop, project_id],
                    :username => HelpdeskSettings[:helpdesk_username, project_id],
                    :password => HelpdeskSettings[:helpdesk_password, project_id],
                    :folder => HelpdeskSettings[:helpdesk_imap_folder, project_id],
                    :move_on_success => HelpdeskSettings[:helpdesk_move_on_success, project_id],
                    :move_on_failure => HelpdeskSettings[:helpdesk_move_on_failure, project_id],
                    :delete_unprocessed => HelpdeskSettings[:helpdesk_delete_unprocessed, project_id].to_i > 0
                    }
    options = { :issue => {} }
    options[:issue][:project_id] = project_id
    options[:issue][:status_id] = HelpdeskSettings[:helpdesk_new_status, project_id]
    options[:issue][:assigned_to_id] = HelpdeskSettings[:helpdesk_assigned_to, project_id]
    options[:issue][:tracker_id] = HelpdeskSettings[:helpdesk_tracker, project_id]
    options[:issue][:priority_id] = HelpdeskSettings[:helpdesk_issue_priority, project_id]
    options[:issue][:due_date] = HelpdeskSettings[:helpdesk_issue_due_date, project_id]
    options[:issue][:reopen_status_id] = HelpdeskSettings[:helpdesk_reopen_status, project_id]

    [mail_options, options]
  end

  def auto_answer(contact, issue)
    headers['X-Redmine-Ticket-ID'] = issue.id.to_s
    headers['X-Auto-Response-Suppress'] = 'oof'

    confirmation_body = self.class.apply_macro(HelpdeskSettings[:helpdesk_first_answer_template, issue.project_id], contact, issue)

    @email_stylesheet = HelpdeskSettings[:helpdesk_helpdesk_css, issue.project_id].to_s.html_safe
    @email_body = confirmation_body
    from_address = HelpdeskSettings[:helpdesk_answer_from, issue.project].blank? ? Setting.mail_from : HelpdeskSettings[:helpdesk_answer_from, issue.project]

    mail :from => from_address,
         :to => contact.primary_email,
         :subject => self.class.apply_macro(HelpdeskSettings[:helpdesk_first_answer_subject, issue.project_id], contact, issue) || "Helpdesk auto answer [Case ##{issue.id}]"  do |format|
      format.text { render 'email_layout'}
      format.html { render 'email_layout' } unless RedmineHelpdesk.settings[:plain_text_mail]
    end

    logger.info  "Helpdesk MailHandler: Sending confirmation" if logger && logger.info
  end

  def self.apply_macro(text, contact, issue, journal_user=nil)
    return '' if text.blank?
    text = text.gsub(/%%NAME%%|\{%contact.first_name%\}/, contact.first_name)
    text = text.gsub(/%%FULL_NAME%%|\{%contact.name%\}/, contact.name)
    text = text.gsub(/%%COMPANY%%|\{%contact.company%\}/, contact.company) if contact.company
    text = text.gsub(/%%LAST_NAME%%|\{%contact.last_name%\}/, contact.last_name.blank? ? "" : contact.last_name)
    text = text.gsub(/%%MIDDLE_NAME%%|\{%contact.middle_name%\}/, contact.middle_name.blank? ? "" : contact.middle_name)
    text = text.gsub(/%%DATE%%|\{%date%\}/, ApplicationHelper.format_date(Date.today))
    text = text.gsub(/%%ASSIGNEE%%|\{%ticket.assigned_to%\}/, issue.assigned_to.blank? ? "" : issue.assigned_to.name)
    text = text.gsub(/%%ISSUE_ID%%|\{%ticket.id%\}/, issue.id.to_s) if issue.id
    text = text.gsub(/%%ISSUE_TRACKER%%|\{%ticket.tracker%\}/, issue.tracker.name) if issue.tracker
    text = text.gsub(/%%QUOTED_ISSUE_DESCRIPTION%%|\{%ticket.quoted_description%\}/, issue.description.gsub(/^/, "> ")) if issue.description
    text = text.gsub(/%%PROJECT%%|\{%ticket.project%\}/, issue.project.name) if issue.project
    text = text.gsub(/%%SUBJECT%%|\{%ticket.subject%\}/, issue.subject) if issue.subject
    text = text.gsub(/%%NOTE_AUTHOR%%|\{%response.author%\}/, journal_user.name) if journal_user
    text = text.gsub(/%%NOTE_AUTHOR.FIRST_NAME%%|\{%response.author.first_name%\}/, journal_user.firstname) if journal_user
    text = text.gsub(/\{%ticket.status%\}/, issue.status.name) if issue.status
    text = text.gsub(/\{%ticket.priority%\}/, issue.priority.name) if issue.priority
    text = text.gsub(/\{%ticket.estimated_hours%\}/, issue.estimated_hours.to_s) if issue.estimated_hours
    text = text.gsub(/\{%ticket.done_ratio%\}/, issue.done_ratio.to_s) if issue.done_ratio
    text = text.gsub(/\{%ticket.public_url%\}/, Setting.protocol + '://' + Setting.host_name + Rails.application.routes.url_helpers.public_ticket_path(issue.helpdesk_ticket.id, issue.helpdesk_ticket.token) ) if issue.helpdesk_ticket

    if text =~ /\{%ticket.history%\}/
      ticket_history = ''
      issue.journals.includes(:journal_message).map(&:journal_message).compact.each do |journal_message|
        message_author = "*#{l(:label_crm_added_by)} #{journal_message.is_incoming? ? journal_message.from_address : journal_message.journal.user.name}, #{format_time(journal_message.message_date)}*"
        ticket_history = (message_author + "\n" + journal_message.journal.notes + "\n" + ticket_history).gsub(/^/, "> ")
      end
      text = text.gsub(/\{%ticket.history%\}/, ticket_history)
    end

    issue.custom_field_values.each do |value|
      text = text.gsub(/%%#{value.custom_field.name}%%/, value.value.to_s)
    end

    contact.custom_field_values.each do |value|
      text = text.gsub(/%%#{value.custom_field.name}%%/, value.value.to_s)
    end if contact.respond_to?("custom_field_values")

    text
  end

  private

  def dispatch
    m = email.subject && email.subject.match(ISSUE_REPLY_SUBJECT_RE)
    journal_message = !email.in_reply_to.blank? && JournalMessage.find_by_message_id(email.in_reply_to)
    if journal_message && journal_message.journal && journal_message.journal.issue
      receive_issue_reply(journal_message.journal.issue.id)
    elsif m && Issue.exists?(m[1].to_i)
      receive_issue_reply(m[1].to_i)
    else
      dispatch_to_default
    end
  rescue MissingInformation => e
    logger.error "Helpdesk MailHandler: missing information from #{user}: #{e.message}" if logger
    false
  rescue UnauthorizedAction => e
    logger.error "Helpdesk MailHandler: unauthorized attempt from #{user}" if logger
    false
  rescue Exception => e
    # TODO: send a email to the user
    logger.error "Helpdesk MailHandler: dispatch error #{e.message}" if logger
    false
  end

  def dispatch_to_default
    receive_issue
  end

  def target_project
    @target_project ||= Project.find(get_keyword(:project_id))
    raise MissingInformation.new('Unable to determine target project') if @target_project.nil?
    @target_project
  end

  def helpdesk_issue_attributes_from_keywords(issue)
    # assigned_to = ((k = get_keyword(:assigned_to_id, :override => true)) && User.find_by_id(k)) || ((k = get_keyword(:assigned_to, :override => true)) && find_user_from_keyword(k))
    assigned_to = ((k = get_keyword(:assigned_to_id, :override => true)) && (User.find_by_id(k) || Group.find_by_id(k))) || ((k = get_keyword(:assigned_to, :override => true)) && find_user_from_keyword(k))

    attrs = {
      'tracker_id' => ((k = get_keyword(:tracker)) && issue.project.trackers.named(k).first.try(:id)) || ((k = get_keyword(:tracker_id)) && issue.project.trackers.find(k).try(:id)),
      'status_id' =>  ((k = get_keyword(:status)) && IssueStatus.named(k).first.try(:id) ) || ((k = get_keyword(:status_id)) && IssueStatus.find(k).try(:id)),
      'priority_id' => ((k = get_keyword(:priority)) && IssuePriority.named(k).first.try(:id)) || ((k = get_keyword(:priority_id)) && IssuePriority.find(k).try(:id)),
      'category_id' => (k = get_keyword(:category)) && issue.project.issue_categories.named(k).first.try(:id),
      'assigned_to_id' => assigned_to.try(:id),
      'fixed_version_id' => (k = get_keyword(:fixed_version, :override => true)) && issue.project.shared_versions.named(k).first.try(:id),
      'start_date' => get_keyword(:start_date, :override => true, :format => '\d{4}-\d{2}-\d{2}'),
      'due_date' => get_keyword(:due_date, :override => true, :format => '\d{4}-\d{2}-\d{2}'),
      'estimated_hours' => get_keyword(:estimated_hours, :override => true),
      'done_ratio' => get_keyword(:done_ratio, :override => true, :format => '(\d|10)?0')
    }.delete_if {|k, v| v.blank? }

    if issue.new_record? && attrs['tracker_id'].nil?
      attrs['tracker_id'] = issue.project.trackers.find(:first).try(:id)
    end

    attrs
  end

  # Creates a new issue
  def receive_issue
    project = target_project
    issue = Issue.new(:author => user, :project => project)
    issue.safe_attributes = helpdesk_issue_attributes_from_keywords(issue)
    issue.safe_attributes = {'custom_field_values' => custom_field_values_from_keywords(issue)}
    issue.subject = cleaned_up_subject
    issue.subject = '(no subject)' if issue.subject.blank?
    issue.description = cleaned_up_text_body

    helpdesk_ticket = HelpdeskTicket.new(:from_address => email.from_addrs.first.to_s.downcase,
                                        :to_address => email.to_addrs.join(',').downcase,
                                        :cc_address => email.cc_addrs.join(',').downcase,
                                        :ticket_date => email.date || Time.now,
                                        :message_id => email.message_id,
                                        :is_incoming => true,
                                        :customer => contact,
                                        :issue => issue,
                                        :source => HelpdeskTicket::HELPDESK_EMAIL_SOURCE)

    issue.helpdesk_ticket = helpdesk_ticket
    issue.contacts << cc_contacts if HelpdeskSettings[:helpdesk_save_cc, target_project.id].to_i > 0

    save_email_as_attachment(helpdesk_ticket) if HelpdeskSettings[:helpdesk_save_as_attachment, target_project].to_i > 0
    add_attachments(issue)

    Redmine::Hook.call_hook(:helpdesk_mailer_receive_issue_before_save, { :issue => issue, :contact => contact, :helpdesk_ticket => helpdesk_ticket, :email => email})

    ActiveRecord::Base.transaction do
      issue.save!
      ContactNote.create(:content => "*#{issue.subject}* [#{issue.tracker.name} - ##{issue.id}]\n\n" + issue.description,
                                       :type_id => Note.note_types[:email],
                                       :source => contact,
                                       :author_id => issue.author_id) if HelpdeskSettings[:helpdesk_add_contact_notes, project]
      begin
        HelpdeskMailer.auto_answer(contact, issue).deliver if HelpdeskSettings[:helpdesk_send_notification, project].to_i > 0
      rescue Exception => e
        logger.error "Helpdesk MailHandler Error: notification was not sent #{e.message}" if logger
        false
      end

      logger.info "Helpdesk MailHandler: issue ##{issue.id} created by #{user} for #{contact.name}" if logger && logger.info
      issue
    end #transaction

  end

  # Adds a note to an existing issue
  def receive_issue_reply(issue_id)
    issue = Issue.find_by_id(issue_id)
    return unless issue
    # if lifetime expaired create new issue
    if (HelpdeskSettings[:helpdesk_lifetime, target_project].to_i > 0) && issue.journals && issue.journals.last && ((Date.today) - issue.journals.last.created_on.to_date > HelpdeskSettings[:helpdesk_lifetime, target_project].to_i)
      email.subject = email.subject.to_s.gsub(ISSUE_REPLY_SUBJECT_RE, '')
      return receive_issue
    end
    journal = issue.init_journal(user)
    journal.notes = cleaned_up_text_body

    journal_message = JournalMessage.create(:from_address => email.from_addrs.first.to_s.downcase,
                                            :to_address => email.to_addrs.join(',').downcase,
                                            :bcc_address => email.bcc_addrs.join(',').downcase,
                                            :cc_address => email.cc_addrs.join(',').downcase,
                                            :message_id => email.message_id,
                                            :is_incoming => true,
                                            :message_date => email.date || Time.now,
                                            :contact => contact,
                                            :journal => journal)

    issue.contacts << cc_contacts if HelpdeskSettings[:helpdesk_save_cc, target_project.id].to_i > 0

    add_attachments(issue)

    if HelpdeskSettings[:helpdesk_save_as_attachment, target_project].to_i > 0
      eml_attachment = save_email_as_attachment(journal_message, "reply-#{DateTime.now.strftime('%d.%m.%y-%H.%M.%S')}.eml")
    end

    if reopen_status_id = ((k = @@helpdesk_mailer_options[:reopen_status]) && IssueStatus.named(k).first.try(:id) ) || ((k = get_keyword(:reopen_status_id)) && IssueStatus.find_by_id(k).try(:id))
      issue.status_id = reopen_status_id
    end

    issue.save!
    logger.info "Helpdesk MailHandler: issue ##{issue.id} updated by #{user}" if logger && logger.info
    journal
  end

  # Reply will be added to the issue
  def receive_journal_reply(journal_id)
    journal = Journal.find_by_id(journal_id)
    if journal && journal.journalized_type == 'Issue'
      receive_issue_reply(journal.journalized_id)
    end
  end

  def add_attachments(obj)
    # debugger
    fwd_attachments = email.parts.map { |p|
                        if p.content_type =~ /message\/rfc822/
                          Mail.new(p.body).attachments
                        elsif p.parts.empty?
                          p if p.attachment?
                        else
                          p.attachments
                        end
                      }.flatten.compact

    email_attachments = fwd_attachments | email.attachments

    unless email_attachments.blank?
      email_attachments.each do |attachment|
        if RUBY_VERSION < '1.9'
          attachment_filename = (attachment[:content_type].filename rescue nil) ||
                                (attachment[:content_disposition].filename rescue nil) ||
                                (attachment[:content_location].location rescue nil) ||
                                "attachment"
          attachment_filename = Mail::Encodings.unquote_and_convert_to(attachment_filename, 'utf-8')
        else
          attachment_filename = attachment.filename
        end

        obj.attachments << Attachment.new(:container => obj,
                                          :file => (attachment.decoded rescue nil) || (attachment.decode_body rescue nil) || attachment.raw_source,
                                          :filename => attachment_filename,
                                          :author => user,
                                          :content_type => attachment.mime_type)
        logger.info "Helpdesk MailHandler: attachment #{attachment_filename} added to object ID: #{obj.id}" if logger && logger.info
      end
    end
  end

  def get_keyword(attr, options={})
    @keywords ||= {}
    if @keywords.has_key?(attr)
      @keywords[attr]
    else
      @keywords[attr] = @@helpdesk_mailer_options[:issue][attr]
    end
  end

  def find_user_from_keyword(keyword)
    user ||= User.find_by_mail(keyword)
    user ||= User.find_by_login(keyword)
    if user.nil? && keyword.match(/ /)
      firstname, lastname = *(keyword.split) # "First Last Throwaway"
      user ||= User.find_by_firstname_and_lastname(firstname, lastname)
    end
    user
  end

  def check_blacklist?(email)
    return true if HelpdeskSettings[:helpdesk_blacklist, target_project].blank?
    addr = email.from_addrs.first.to_s.strip
    from_addr = addr # (addr && !addr.spec.blank?) ? addr.spec : email.header["from"].inspect.match(/[-A-z0-9.]+@[-A-z0-9.]+/).to_s
    cond = "(" + HelpdeskSettings[:helpdesk_blacklist, target_project].split("\n").map{|u| u.strip unless u.blank?}.compact.join('|') + ")"
    !from_addr.match(cond)
  end

  def new_contact_from_attributes(email_address, fullname=nil)
    contact = Contact.new

    # Truncating the email address would result in an invalid format
    contact.email = email_address
    names = fullname.blank? ? email_address.gsub(/@.*$/, '').split('.') : fullname.split
    contact.first_name = names.shift.slice(0, 255)
    contact.last_name = names.join(' ').slice(0, 255)
    contact.company = email_address.downcase.slice(0, 255)
    contact.last_name = '-' if contact.last_name.blank?
    contact.projects << target_project
    contact.tag_list = HelpdeskSettings[:helpdesk_created_contact_tag, target_project] if HelpdeskSettings[:helpdesk_created_contact_tag, target_project]

    contact
  end

  def cc_contacts
    email[:cc].to_s
    email.cc_addrs.each_with_index.map do |cc_addr, index|
      cc_name = email[:cc].display_names[index]
      create_contact_from_address(cc_addr, cc_name)
    end.compact
  end

  def create_contact_from_address(addr, name)
    contacts = Contact.find_by_emails([addr])
    unless contacts.blank?
      contact = contacts.first
      if HelpdeskSettings[:helpdesk_add_contact_to_project, target_project].to_i > 0
        contact.projects << target_project
        contact.save!
      end

      return contact
    end

    if HelpdeskSettings[:helpdesk_is_not_create_contacts, target_project].to_i > 0
      logger.error "HelpdeskMailHandler: can't find contact with email: #{addr} in whitelist. Not create new contacts option enable" if logger
      nil
    else
      contact = new_contact_from_attributes(addr, name)
      if contact.save
        contact
      else
        logger.error "HelpdeksMailHandler: failed to create Contact: #{contact.errors.full_messages}" if logger
        nil
      end
    end
  end

  # Get or create contact for the +email+ sender
  def contact_from_email(email)
    # from = email.header['from'].to_s
    # debugger
    from = cleaned_up_from_address
    addr, name = from, nil
    if m = from.match(/^"?(.+?)"?\s+<(.+@.+)>$/)
      addr, name = m[2], m[1]
    end
    if addr.present?
       create_contact_from_address(addr, name)
    else
      logger.error "HelpdeskMailHandler: failed to create Contact: no FROM address found" if logger
      nil
    end

  end

  # Returns a Hash of issue custom field values extracted from keywords in the email body
  def custom_field_values_from_keywords(customized)
    customized.custom_field_values.inject({}) do |h, v|
      if value = get_keyword(v.custom_field.name, :override => true)
        h[v.custom_field.id.to_s] = value
      end
      h
    end
  end

  def save_email_as_attachment(container, filename="message.eml")
    Attachment.create(:container => container,
                      :file => email.raw_source.to_s,
                      :author => user,
                      :filename => filename,
                      :content_type => "message/rfc822")
  end

  def plain_text_body
    return @plain_text_body unless @plain_text_body.nil?
    part = email.text_part || email.html_part || email

    is_plain = !email.text_part.blank?
    @plain_text_body = if part.body.decoded.respond_to?(:force_encoding)
      encode_to_utf8(part.body.decoded, part.charset)
    else
      Redmine::CodesetUtil.to_utf8(part.body.decoded, part.charset)
    end

    # strip html tags and remove doctype directive
    @plain_text_body.gsub! %r{^[ ]+}, ''
    unless is_plain
      @plain_text_body.gsub! %r{<head>(?:.|\n|\r)+?<\/head>}, ""
      @plain_text_body.gsub! %r{<\/(li|ol|ul|h1|h2|h3|h4)>}, "\r\n"
      @plain_text_body.gsub! %r{<\/(p|div|pre)>}, "\r\n\r\n"
      @plain_text_body.gsub! %r{<li>}, "  - "
      @plain_text_body.gsub! %r{<br[^>]*>}, "\r\n"
      @plain_text_body = strip_tags(@plain_text_body.strip)
      @plain_text_body.sub! %r{^<!DOCTYPE .*$}, ''
    end
    @plain_text_body.strip

  rescue Exception => e
    logger.error "Helpdesk MailHandler Error: [message body processing] - #{e.message}" if logger && logger.error
    @plain_text_body = '(Unprocessable message body)'
  end

  def cleaned_up_from_address
    from = email.header['from'].to_s
    from.strip[0,255]
  end

  def logger
    Rails.logger
  end

  def encode_to_utf8(str, encoding)
    cleaned = str.force_encoding('UTF-8')
    unless cleaned.valid_encoding?
      cleaned = str.encode( 'UTF-8', encoding ).chars.select{|i| i.valid_encoding?}.join
    end
    content = cleaned
  rescue EncodingError
    content.encode!( 'UTF-8', :invalid => :replace, :undef => :replace )
  end

end
