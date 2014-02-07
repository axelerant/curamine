require File.expand_path('../../test_helper', __FILE__)

class MailHandlerPatchTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/',
                            [:contacts,
                             :contacts_projects,
                             :contacts_issues,
                             :deals,
                             # :roles,
                             # :enabled_modules,
                             :notes,
                             :tags,
                             :taggings,
                             :contacts_queries])

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/',
                            [:journal_messages])

  include RedmineHelpdesk::TestHelper

  def setup
    RedmineHelpdesk::TestCase.prepare

    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'

    Setting.notified_events = Redmine::Notifiable.all.collect(&:name)
  end

  def test_send_mail_to_contact
    issue = Issue.find(5)
    contact = Contact.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!
    RedmineHelpdesk.settings[:send_note_by_default] = false
    journal = submit_email('reply_from_mail.eml')
    assert_instance_of Journal, journal
    assert !journal.new_record?
    assert last_email.to.include?(contact.emails.first)
    assert !last_email.parts.first.body.to_s.blank?
    journal.reload
    assert_no_match /^@@sendmail@@\s*/, journal.notes
    assert_match /This is a reply from mail/, journal.notes
  end

  def test_send_mail_to_contact_by_default
    issue = Issue.find(5)
    contact = Contact.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!
    RedmineHelpdesk.settings[:send_note_by_default] = true
    journal = submit_email('reply_from_mail_by_default.eml')
    assert_instance_of Journal, journal
    assert !journal.new_record?
    assert_equal issue.helpdesk_ticket.from_address, last_email.to.first.to_s
    assert !last_email.parts.first.body.to_s.blank?
    journal.reload
    assert_match /This is a reply from mail by default/, journal.notes
  end

  def test_should_assign_user_to_unassigned_issue
    issue = Issue.find(5)
    issue.assigned_to = nil
    contact = Contact.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!
    RedmineHelpdesk.settings[:send_note_by_default] = true
    journal = submit_email('reply_from_mail_by_default.eml')
    assert_instance_of Journal, journal
    assert_equal journal.user, journal.issue.assigned_to
  end

  def test_should_assign_new_status
    issue = Issue.find(5)
    issue.assigned_to = nil
    issue.status_id = IssueStatus.last.id
    ContactsSetting[:helpdesk_new_status, issue.project_id] = IssueStatus.first.id
    contact = Contact.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!
    RedmineHelpdesk.settings[:send_note_by_default] = true
    journal = submit_email('reply_from_mail_by_default.eml')
    assert_instance_of Journal, journal
    assert_equal IssueStatus.first, journal.issue.status
  end

  def test_should_not_send_mail_to_contact_by_default
    issue = Issue.find(5)
    contact = Contact.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!
    RedmineHelpdesk.settings[:send_note_by_default] = false
    journal = submit_email('reply_from_mail_by_default.eml')
    assert_instance_of Journal, journal
    assert_equal "", last_email.to.first.to_s
  end

  def test_should_not_send_mail_to_contact_by_default_with_empty_body
    issue = Issue.find(5)
    contact = Contact.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!
    assert_not_equal 'Closed', issue.status.name
    RedmineHelpdesk.settings[:send_note_by_default] = true
    Setting.mail_handler_body_delimiters = "---- This should be cutted ----"
    journal = submit_email('reply_from_mail_with_keywords.eml')
    assert_instance_of Journal, journal
    assert_nil ActionMailer::Base.deliveries.last
    assert_nil journal.journal_message
  end


end
