# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class ContactsMailer < ActionMailer::Base
  include Redmine::I18n

  class UnauthorizedAction < StandardError; end
  class MissingInformation < StandardError; end

  helper :application

  attr_reader :email, :user

  def self.default_url_options
    h = Setting.host_name
    h = h.to_s.gsub(%r{\/.*$}, '') unless Redmine::Utils.relative_url_root.blank?
    { :host => h, :protocol => Setting.protocol }
  end

  def bulk_mail(contact, params = {})
    raise l(:error_empty_email) if (contact.emails.empty? || params[:message].blank?)

    @contact = contact
    @params = params

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

    mail(:from => params[:from] || User.current.mail,
         :to => contact.emails.first,
         :cc => params[:cc],
         :bcc => params[:bcc],
         :subject => params[:subject]) do |format|
       format.text
       format.html
    end

  end

  def self.receive(email, options={})
    @@contacts_mailer_options = options.dup
    super email
  end

  # Processes incoming emails
  # Returns the created object (eg. an issue, a message) or false
  def receive(email)
    # debugger
    @email = email
    sender_email = email.from.to_a.first.to_s.strip
    # Ignore emails received from the application emission address to avoid hell cycles
    if sender_email.downcase == Setting.mail_from.to_s.strip.downcase
      logger.info  "ContactsMailHandler: ignoring email from Redmine emission address [#{sender_email}]" if logger && logger.info
      return false
    end
    @user = User.find_by_mail(sender_email) if sender_email.present?
    if @user.nil? || (@user && !@user.active?)
      logger.info   "ContactsMailHandler: user not found [#{sender_email}]" if logger && logger.info
    end
    dispatch
  end

  def dispatch

    deal_id = email.to.to_s.match(/.+\+d([0-9]*)/).to_a[1]
    deal_id ||= email.bcc.to_s.match(/.+\+d([0-9]*)/).to_a[1]
    deal_id ||= email.cc.to_s.match(/.+\+d([0-9]*)/).to_a[1]

    if deal_id
      deal = Deal.find_by_id(deal_id)
      if deal
        return [*receive_deal_note(deal_id)]
      end
    end

    contacts = []

    if contacts.blank?
      contact_id = email.to.to_s.match(/.+\+c([0-9]*)/).to_a[1]
      contact_id ||= email.bcc.to_s.match(/.+\+c([0-9]*)/).to_a[1]
      contact_id ||= email.cc.to_s.match(/.+\+c([0-9]*)/).to_a[1]
      contacts = Contact.find_all_by_id(contact_id)
    end

    if contacts.blank?
      contacts = Contact.find_by_emails(email.to.to_a)
    end

    if contacts.blank?
      from_key_words = get_keyword_locales(:label_crm_mail_from)
      @plain_text_body = plain_text_body.gsub(/^>\s*/, '')
      full_address = plain_text_body.match(/^(#{from_key_words.join('|')})[ \s]*:[ \s]*(.+)\s*$/).to_a[2]

      email_address = full_address.match(/[\w,\.,\-,\+]+@.+\.\w{2,}/) if full_address
      contacts = Contact.find_by_emails(email_address.to_s.strip.to_a) if email_address
    end

    if contacts.blank?
      return false
    end

    raise MissingInformation if contacts.blank?

    result = []
    contacts.each do |contact|
      result << receive_contact_note(contact.id)
    end
    result

  rescue ActiveRecord::RecordInvalid => e
    # TODO: send a email to the user
    logger.error e.message if logger
    false
  rescue MissingInformation => e
    logger.error "ContactsMailHandler: missing information from #{user}: #{e.message}" if logger
    false
  rescue UnauthorizedAction => e
    logger.error "ContactsMailHandler: unauthorized attempt from #{user}" if logger
    false
  end

  # Receives a reply to a forum message
  def receive_contact_note(contact_id)
    contact = Contact.find_by_id(contact_id)
    note = nil
    # logger.error "ContactsMailHandler: receive_contact_note user: #{user},
    #               contact: #{contact.name},
    #               editable: #{contact.editable?(self.user)},
    #               current: #{User.current}"
    raise UnauthorizedAction unless contact.editable?(self.user)
    if contact
        note = ContactNote.new(:subject => email.subject.gsub(%r{^.*msg\d+\]}, '').strip,
                        :type_id => Note.note_types[:email],
                        :content => plain_text_body,
                        :created_on => email.date)
        note.author = self.user
        contact.notes << note
        add_attachments(note)
        logger.info note
        note.save
        contact.save
    end
    note
  end

  def receive_deal_note(deal_id)
    deal = Deal.find_by_id(deal_id)
    note = nil
    # logger.error "ContactsMailHandler: receive_contact_note user: #{user},
    #               contact: #{contact.name},
    #               editable: #{contact.editable?(self.user)},
    #               current: #{User.current}"
    raise UnauthorizedAction unless deal.editable?(self.user)
    if deal
        note = DealNote.new(:subject => email.subject.gsub(%r{^.*msg\d+\]}, '').strip,
                        :type_id => Note.note_types[:email],
                        :content => plain_text_body,
                        :created_on => email.date)
        note.author = self.user
        deal.notes << note
        add_attachments(note)
        logger.info note
        note.save
        deal.save
    end
    note
  end

  private

  # Destructively extracts the value for +attr+ in +text+
  # Returns nil if no matching keyword found
  def extract_keyword!(text, attr, format=nil)
    keys = [attr.to_s.humanize]
    if attr.is_a?(Symbol)
      keys << l("field_#{attr}", :default => '', :locale =>  user.language) if user && user.language.present?
      keys << l("field_#{attr}", :default => '', :locale =>  Setting.default_language) if Setting.default_language.present?
    end
    keys.reject! {|k| k.blank?}
    keys.collect! {|k| Regexp.escape(k)}
    format ||= '.+'
    text.gsub!(/^(#{keys.join('|')})[ \t]*:[ \t]*(#{format})\s*$/i, '') # /^(От:)[ \t]*:[ \t]*(.+)\s*$/i
    $2 && $2.strip
  end

  def add_attachments(obj)
    if email.attachments && email.attachments.any?
      email.attachments.each do |attachment|
        obj.attachments << Attachment.create(:container => obj,
                          :file => attachment.decoded,
                          :filename => attachment.filename,
                          :author => user,
                          :content_type => attachment.mime_type)
      end
    end
  end

  # Returns the text/plain part of the email
  # If not found (eg. HTML-only email), returns the body with tags removed
  def plain_text_body

    return @plain_text_body unless @plain_text_body.nil?

    part = email.text_part || email.html_part || email
    @plain_text_body = Redmine::CodesetUtil.to_utf8(part.body.decoded, part.charset)

    # strip html tags and remove doctype directive
    @plain_text_body = ActionController::Base.helpers.strip_tags(@plain_text_body.strip) unless email.text_part
    @plain_text_body.sub! %r{^<!DOCTYPE .*$}, ''
    @plain_text_body

  end

  def get_keyword_locales(keyword)
    I18n.available_locales.collect{|lc| l(keyword, :locale => lc)}.uniq
  end

  # Appends a Redmine header field (name is prepended with 'X-Redmine-')
  def redmine_headers(h)
    h.each { |k,v| headers["X-Redmine-#{k}"] = v }
  end

  def initialize_defaults(method_name)
    super
    # Common headers
    headers 'X-Mailer' => 'Redmine Contacts',
            'X-Redmine-Host' => Setting.host_name,
            'X-Redmine-Site' => Setting.app_title
  end

  def logger
    Rails.logger
  end

end
