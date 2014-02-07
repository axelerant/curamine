# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class HelpdeskMailerTest < ActiveSupport::TestCase
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
                             :notes,
                             :tags,
                             :taggings,
                             :contacts_queries])

    ActiveRecord::Fixtures.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/',
                            [:journal_messages,
                             :helpdesk_tickets])

  include RedmineHelpdesk::TestHelper

  def setup
    RedmineHelpdesk::TestCase.prepare

    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'

    Setting.notified_events = Redmine::Notifiable.all.collect(&:name)
  end

  test "Should add issue and contact" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    ContactsSetting[:helpdesk_created_contact_tag, Project.find('ecookbook').id] = 'test,main'
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    ContactsSetting[:helpdesk_send_notification, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal issue, Issue.find_by_subject('New support issue from email')
    contact = issue.customer

    assert_not_nil issue.helpdesk_ticket.ticket_date
    assert_equal "support@somenet.foo", issue.helpdesk_ticket.to_address
    assert_equal "new_customer@somenet.foo", issue.helpdesk_ticket.from_address
    assert_equal "New", contact.first_name
    assert_equal "Customer-Name", contact.last_name
    assert_equal "new_customer@somenet.foo", contact.company
    assert contact.tag_list.include?('test')
    assert contact.tag_list.include?('main')
    assert_equal 'ecookbook', contact.project.identifier
    assert_equal "new_customer@somenet.foo", contact.email
    assert last_email.from.include?('test@email.from')
    assert last_email.to.include?(contact.emails.first)
    assert !last_email.parts.first.body.to_s.blank?
  end

  test "Should assign to duplicated contact" do
    ActionMailer::Base.deliveries.clear
    Contact.create(:first_name => "New",
                   :last_name => "Customer-Name",
                   :company => "Somenet.foo",
                   :email => "customer@somenet.foo",
                   :projects => [Project.find('ecookbook')])

    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    contact = issue.customer

    assert_not_nil issue.helpdesk_ticket.ticket_date
    assert_equal "support@somenet.foo", issue.helpdesk_ticket.to_address
    assert_equal "new_customer@somenet.foo", issue.helpdesk_ticket.from_address
    assert_equal "New", contact.first_name
    assert_equal "Customer-Name", contact.last_name
    assert_equal "new_customer@somenet.foo", contact.company
    assert_equal 'ecookbook', contact.project.identifier
    assert_match "new_customer@somenet.foo", contact.email
  end

  test "Should add duplicated contact" do
    ActionMailer::Base.deliveries.clear
    duplicate = Contact.create(:first_name => "new_customer",
                               :last_name => "-",
                               :company => "Somenet.foo",
                               :email => "customer@somenet.foo",
                               :projects => [Project.find('ecookbook')])

    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('ticket_without_name.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    contact = issue.customer

    assert_not_nil issue.helpdesk_ticket.ticket_date
    assert_equal "support@somenet.foo", issue.helpdesk_ticket.to_address
    assert_equal "new_customer@somenet.foo", issue.helpdesk_ticket.from_address
    assert_equal 'new_customer', contact.first_name
    assert_equal "-", contact.last_name
    assert_equal "new_customer@somenet.foo", contact.company
    assert_equal 'ecookbook', contact.project.identifier
    assert_match "new_customer@somenet.foo", contact.email
  end

  test "Should assign ticket to group" do
    ActionMailer::Base.deliveries.clear
    group = Group.last
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => {:project_id => 'ecookbook', :assigned_to_id => group.id})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal group, issue.assigned_to
  end

  test "Should assign ticket to user" do
    ActionMailer::Base.deliveries.clear
    user = User.last
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => {:project_id => 'ecookbook', :assigned_to_id => user.id})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal user, issue.assigned_to
  end

  test "Should set author from redmine user" do
    ActionMailer::Base.deliveries.clear
    user = User.find(2)
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    ContactsSetting[:helpdesk_assign_author, Project.find('ecookbook').id] = "1"
    issue = submit_helpdesk_email('ticket_from_redmine_user.eml', :issue => {:project_id => 'ecookbook', :assigned_to_id => user.id})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal user, issue.author
  end

  test "Should recieve ticket without to address" do
    ActionMailer::Base.deliveries.clear
    issue = submit_helpdesk_email('ticket_with_empty_to.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal issue, Issue.find_by_subject('New support issue from email')
    contact = issue.customer

    assert_not_nil issue.helpdesk_ticket.ticket_date
    assert_equal "new_customer@somenet.foo", issue.helpdesk_ticket.from_address
    assert_equal "", issue.helpdesk_ticket.to_address
    assert_equal "New", contact.first_name
    assert_equal "Customer-Name", contact.last_name
  end

  test "Should not recieve ticket without from address" do
    ActionMailer::Base.deliveries.clear
    issue = submit_helpdesk_email('ticket_with_empty_from.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal false, issue
  end

  test "Should add contact with bad name" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    ContactsSetting[:helpdesk_send_notification, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('new_contact_bad_name.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal issue, Issue.find_by_subject('New support issue from email')
    contact = issue.customer
    assert_equal "New\"", contact.first_name
    assert_equal "\"Customer\"", contact.last_name
    assert_equal "new_customer@somenet.foo", contact.email
    assert last_email.from.include?('test@email.from')
    assert last_email.to.include?(contact.emails.first)
    assert !last_email.parts.first.body.to_s.blank?
  end

  test "Should add contact with unicode name" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    ContactsSetting[:helpdesk_send_notification, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('new_contact_unicode_name.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal issue, Issue.find_by_subject('New support issue from email')
    contact = issue.customer
    assert_equal "Кирилл", contact.first_name
    assert_equal "Безруков", contact.last_name
    assert_equal "new_customer@somenet.foo", contact.email
    assert last_email.from.include?('test@email.from')
    assert last_email.to.include?(contact.emails.first)
    assert !last_email.parts.first.body.to_s.blank?
  end

  test "Should add new issue and contact with encoded name" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    ContactsSetting[:helpdesk_send_notification, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('new_issue_new_contact_encode.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload

    assert_equal issue, Issue.find_by_subject('Проверка')
    contact = issue.customer
    assert_equal "Кирилл", contact.first_name
    assert_equal "Безруков", contact.last_name
    assert_equal "aminov1982@gmail.com", contact.email
    assert last_email.from.include?('test@email.from')
    assert last_email.to.include?(contact.emails.first)
    assert !last_email.parts.first.body.to_s.blank?
  end

  test "Should add new issue from html only body" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('ticket_html_only.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload

    assert_match "Header one\r\n", issue.description
    assert_match "    - one\r\n", issue.description
    assert_match "one with line breaks,\r\nparagraph number", issue.description
  end

  test "Should add new issue to contact without subject" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('new_issue_no_subject.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert_equal '(no subject)', issue.subject
  end

  test "Should add issue with rus attachment" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    ContactsSetting[:helpdesk_created_contact_tag, Project.find('ecookbook').id] = 'test,main'
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    ContactsSetting[:helpdesk_send_notification, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('ticket_with_rus_attachment.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    # assert_equal issue, Issue.find_by_subject('New support issue from email')
    contact = issue.customer
    assert_equal "Русская тема Apple Mail", issue.subject
    assert_match 'В этом письме аттач с русским названием', issue.description
    attachment = issue.attachments.last
    assert_not_nil attachment
    assert_equal 'Аттач номер один.rtf', attachment.filename
    assert File.size?(attachment.diskfile) > 0
    assert File.size?(issue.attachments.last.diskfile) > 0
  end

  test "Should add issue and contact ru" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    ContactsSetting[:helpdesk_created_contact_tag, Project.find('ecookbook').id] = 'test,main'
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    ContactsSetting[:helpdesk_send_notification, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('new_issue_new_contact_ru.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    # assert_equal issue, Issue.find_by_subject('New support issue from email')
    contact = issue.customer
    assert_equal "результаты турнира", issue.subject
    assert_equal "Динара", contact.first_name
    assert_equal "Кремчеева", contact.last_name
    assert contact.tag_list.include?('test')
    assert contact.tag_list.include?('main')
    assert_equal 'ecookbook', contact.project.identifier
    assert_equal "kr.dinara@mail.ru", contact.email
    assert last_email.from.include?('test@email.from')
    assert last_email.to.include?(contact.emails.first)
    assert !last_email.parts.first.body.to_s.blank?
    attachment = issue.attachments.last
    assert_equal 'восходящие звезды 2012 6 тур.xml', attachment.filename
    assert_not_nil attachment
    assert File.size?(attachment.diskfile) > 0
    assert File.size?(issue.attachments.last.diskfile) > 0
  end

  test "Should add issue and contact ru 2" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    ContactsSetting[:helpdesk_created_contact_tag, Project.find('ecookbook').id] = 'test,main'
    ContactsSetting[:helpdesk_answer_from, Project.find('ecookbook').id] = 'test@email.from'
    ContactsSetting[:helpdesk_send_notification, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('new_issue_new_contact_ru_2.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    # assert_equal issue, Issue.find_by_subject('New support issue from email')
    contact = issue.customer
    assert_equal "FW: результаты \"Кубка Кремля\"", issue.subject
    assert_equal "Valeria", contact.first_name
    assert_match 'Лера, извини', issue.description
    attachment = issue.attachments.last
    assert_not_nil attachment
    assert_equal '131012.xml', attachment.filename
    assert File.size?(attachment.diskfile) > 0
    assert File.size?(issue.attachments.last.diskfile) > 0
  end

  def test_should_add_issue_and_contact_ru_4
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('new_issue_new_contact_ru_4.eml', :issue => {:project_id => 'ecookbook'})
    issue.reload
    assert_equal Issue, issue.class
    assert_equal '(no subject)', issue.subject
    attachment = issue.attachments.last
    assert_equal 'Кубок Осени - 2012.xml', attachment.filename
    assert File.size?(attachment.diskfile) > 0
  end

  def test_should_add_issue_and_contact_ru_5
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('new_issue_new_contact_ru_5.eml', :issue => {:project_id => 'ecookbook'})
    issue.reload
    assert_equal Issue, issue.class
    assert_equal 'Fwd: Турнир 14 октября 2012 Калининград', issue.subject
    attachment = issue.attachments.last
    assert_equal 'Kaliningrad 14102012.xml', attachment.filename
    assert File.size?(attachment.diskfile) > 0
  end

  def test_should_create_from_quoted_body
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('ticket_with_quotes.eml', :issue => {:project_id => 'ecookbook'})
    issue.reload
    contact = Contact.last
    assert_equal Issue, issue.class
    assert_equal "Максим", contact.first_name
    assert_equal "Скворцов", contact.last_name
    assert_match "Короткое название", issue.description
  end

  def test_should_create_from_koi8_r_body
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('ticket_in_koi8_r.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    issue.reload
    contact = Contact.last
    assert_equal Issue, issue.class
    assert_equal "Шипиев", contact.first_name
    assert_equal "Роман", contact.last_name
    assert_match "Речь идет про плагин", issue.description
  end

  def test_should_create_from_bq_encoded_body
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('ticket_with_bq_encoding.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    issue.reload
    contact = Contact.last
    assert_equal Issue, issue.class
    assert_equal "Плетнёв", contact.first_name
    assert_equal "Алексей", contact.last_name
    assert_match "Ответ на письмо", issue.description
  end

  def test_should_create_with_encoding_iso_8859_15
    return true unless 'str'.respond_to?(:force_encoding)
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('ticket_in_iso_8859_15.eml', :issue => {:project_id => 'ecookbook'})
    issue.reload
    contact = Contact.last
    assert_equal Issue, issue.class
    assert_equal "Joachim", contact.first_name
    assert_equal "Höhl", contact.last_name
    assert_match "Mit freundlichen Grüßen", issue.description
  end

  test "Should add issue and contact with French symbols" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    issue = submit_helpdesk_email('new_issue_french.eml', :issue => {:project_id => 'ecookbook'})
    issue.reload
    assert_equal Issue, issue.class
    assert_equal "email test ok'ok", issue.subject
    attachment = issue.attachments.last
    assert_equal 'image001.jpg', attachment.filename
    assert_match 'the bug ishere', issue.description
    assert File.size?(attachment.diskfile) > 0
  end

  test "Should not add contact" do
    ActionMailer::Base.deliveries.clear
    ContactsSetting[:helpdesk_is_not_create_contacts, Project.find('ecookbook').id] = '1'
    issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal false, issue
    ContactsSetting[:helpdesk_is_not_create_contacts, Project.find('ecookbook').id] = '0'
  end

  test "Should not add contact from blacklist" do
    ActionMailer::Base.deliveries.clear
    ContactsSetting[:helpdesk_blacklist, Project.find('ecookbook').id] = "new_customer@somenet.foo"
    issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal false, issue
    ContactsSetting[:helpdesk_blacklist, Project.find('ecookbook').id] = ""
  end

  test "Should not add contact from blacklist by regexp" do
    ActionMailer::Base.deliveries.clear
    ContactsSetting[:helpdesk_blacklist, Project.find('ecookbook').id] = "new_.*\.foo"
    issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal false, issue
    ContactsSetting[:helpdesk_blacklist, Project.find('ecookbook').id] = ""
  end

  test "Should add issue to contact" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    ContactsSetting[:helpdesk_send_notification, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('new_issue_to_contact.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal issue, Issue.find_by_subject('New support issue to Ivan')
    contact = issue.customer
    assert_equal "Ivan", contact.first_name
    assert last_email.to.include?(contact.emails.first)
  end

  test "Should add project to existing contact" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    onlinestore_project = Project.find_by_identifier('onlinestore')
    ContactsSetting[:helpdesk_answer_from, onlinestore_project.id] = 'test@email.from'
    ContactsSetting[:helpdesk_add_contact_to_project, onlinestore_project.id] = "1"
    issue = submit_helpdesk_email('new_issue_to_contact.eml', :issue => {:project_id => 'onlinestore'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload

    contact = issue.customer
    assert contact.projects.include?(onlinestore_project)
  end

  test "Should attach mail to issue" do
    ActionMailer::Base.deliveries.clear
    # This email contains: 'Project: onlinestore'
    ContactsSetting[:helpdesk_send_notification, Project.find('ecookbook').id] = 1
    ContactsSetting[:helpdesk_save_as_attachment, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal "message.eml", issue.helpdesk_ticket.message_file.filename
    assert issue.helpdesk_ticket.message_file.filesize > 0
  end

  test "Should add issue to contact with params" do
    ActionMailer::Base.deliveries.clear
    issue = submit_helpdesk_email('new_issue_to_contact.eml',
          :issue => {:project_id => 'ecookbook',
                     :priority => 'Urgent',
                     :status => 'Resolved',
                     :tracker => 'Support request',
                     :due_date => '2011-12-12',
                     :assigned_to => 'jsmith'})
    assert_equal Issue, issue.class
    assert !issue.new_record?
    issue.reload
    assert_equal issue, Issue.find_by_subject('New support issue to Ivan')
    assert_equal 'Urgent', issue.priority.name
    # assert_equal 'Assigned', issue.status.name
    assert_equal 'Support request', issue.tracker.name
    assert_equal 'jsmith', issue.assigned_to.login
    assert_equal '2011.12.12'.to_date, issue.due_date
    contact = issue.customer
    assert_equal "Ivan", contact.first_name
    assert last_email.to.include?(contact.emails.first)
  end

  test "Should reply to issue to contact" do
    ActionMailer::Base.deliveries.clear

    issue = Issue.find(5)
    contact = Contact.find(1)

    assert_not_equal 'Feedback', issue.status.name

    journal = submit_helpdesk_email('reply_from_contact.eml', :issue => {:project_id => 'ecookbook'}, :reopen_status => 'Feedback')
    assert_equal Journal, journal.class
    assert !journal.new_record?

    journal.reload
    issue.reload
    contact = journal.issue.customer

    assert_not_nil journal.journal_message.message_date
    assert_equal "support@somenet.foo", journal.journal_message.to_address
    assert_equal "ivan@mail.com", journal.journal_message.from_address
    assert_equal "bcc@somenet.foo", journal.journal_message.bcc_address
    assert_equal "cc@somenet.foo", journal.journal_message.cc_address
    assert_equal 1, journal.contact.id
    assert_equal issue.customer, journal.contact
    assert_equal issue, journal.issue
    assert_equal 'subproject1', journal.issue.project.identifier
    assert_equal "Ivan", contact.first_name
    assert_equal 'Feedback', issue.status.name
  end

  test "Should add cc to issue" do
    ActionMailer::Base.deliveries.clear
    ContactsSetting[:helpdesk_save_cc, Project.find('ecookbook').id] = 1
    issue = submit_helpdesk_email('ticket_with_cc.eml', :issue => {:project_id => 'ecookbook'})
    assert_equal Issue, issue.class

    assert_equal "cc@somenet.foo,marat.aminov@somenet.foo,ivan@somenet.foo", issue.helpdesk_ticket.cc_address
    assert_equal ["Cc -", "Марат Аминов", "Ivanov Ivan"].sort, issue.contacts.map(&:name).sort
  end

  test "Should reply to issue to contact with attachment" do
    ActionMailer::Base.deliveries.clear

    issue = Issue.find(5)

    assert_not_equal 'Feedback', issue.status.name

    # This email contains: 'Project: onlinestore'
    journal = submit_helpdesk_email('reply_with_attachment.eml', :issue => {:project_id => 'ecookbook'}, :reopen_status => 'Feedback')
    assert_equal Journal, journal.class
    assert !journal.new_record?

    journal.reload
    issue.reload
    contact = journal.issue.customer

    assert_equal 1, journal.contact.id
    assert_equal issue.customer, journal.contact
    assert_equal issue, journal.issue
    assert_equal 'subproject1', journal.issue.project.identifier
    assert_equal "Ivan", contact.first_name
    assert_equal 'Feedback', issue.status.name
    attachment = issue.attachments.find_by_filename("Paella.jpg")
    assert_not_nil attachment
    assert File.size?(attachment.diskfile) > 0
    assert File.size?(issue.attachments.last.diskfile) > 0
  end

  test "Should attach email to reply" do
    ActionMailer::Base.deliveries.clear

    issue = Issue.find(5)

    assert_not_equal 'Feedback', issue.status.name

    ContactsSetting[:helpdesk_save_as_attachment, Project.find('ecookbook').id] = 1
    journal = submit_helpdesk_email('reply_from_contact.eml', :issue => {:project_id => 'ecookbook'}, :reopen_status => 'Feedback')
    assert_equal Journal, journal.class
    assert !journal.new_record?

    journal.reload
    issue.reload
    contact = journal.issue.customer

    assert_equal 1, journal.contact.id
    assert_equal issue.customer, journal.contact
    assert_equal issue, journal.issue
    assert_equal "reply-#{DateTime.now.strftime('%d.%m.%y-%H.%M.%S')}.eml".truncate(20), journal.journal_message.message_file.filename.truncate(20)
    assert File.size?(journal.journal_message.message_file.diskfile) > 0
  end

  test "Should deliver received request confirmation" do
    issue = Issue.find(4)
    contact = Contact.find(1)
    assert HelpdeskMailer.auto_answer(contact, issue).deliver
    assert last_email.to.include?(contact.emails.first)
    assert !last_email.parts.first.body.to_s.blank?
  end

  test "Should ignore auto answer" do
    ActionMailer::Base.deliveries.clear

    journal = submit_helpdesk_email('auto_answer.eml', :issue => {:project_id => 'ecookbook'}, :reopen_status => 'Feedback')
    assert_equal false, journal
  end

  # test "Should delete spaces" do
  #   ActionMailer::Base.deliveries.clear
  #   # This email contains: 'Project: onlinestore'
  #   issue = submit_helpdesk_email('ticket_with_leading_spaces_to.eml', :issue => {:project_id => 'ecookbook'})
  #   assert_equal Issue, issue.class
  #   assert !issue.new_record?
  #   issue.reload
  #   assert_equal "", issue.description
  #   assert_match /^[^ ]+.*/, issue.description
  # end

  test "Should deliver response" do
    issue = Issue.find(1)
    contact = Contact.find(1)
    assert HelpdeskMailer.issue_response(contact, issue.journals.last, params = {}).deliver
    assert last_email.to.include?(contact.emails.first)
    assert_equal "Re: #{issue.subject} [#{issue.tracker.name} ##{issue.id}]", last_email.subject
  end

  test "Should replace macro" do
    issue = Issue.find(1)
    issue.assigned_to = User.find(4)
    issue.estimated_hours = 12
    issue.done_ratio = 50
    issue.save!
    contact = Contact.find(1)
    journal = issue.journals.last
    journal.notes = "Full name old: %%FULL_NAME%%\r\n" +
                    "Company old: %%COMPANY%%\r\n" +
                    "Last name old: %%LAST_NAME%%\r\n" +
                    "Middle name old: %%MIDDLE_NAME%%\r\n" +
                    "Date old: %%DATE%%\r\n" +
                    "Assignee old: %%ASSIGNEE%%\r\n" +
                    "Issue ID old: %%ISSUE_ID%%\r\n" +
                    "Issue tracker old: %%ISSUE_TRACKER%%\r\n" +
                    "Issue description old: %%QUOTED_ISSUE_DESCRIPTION%%\r\n" +
                    "Project old: %%PROJECT%%\r\n" +
                    "Subject old: %%SUBJECT%%\r\n" +
                    "Note author old: %%NOTE_AUTHOR%%\r\n" +
                    "Note author first name old: %%NOTE_AUTHOR.FIRST_NAME%%\r\n" +
                    "====================" +
                    "Full name new: {%contact.name%}\r\n" +
                    "Company new: {%contact.company%}\r\n" +
                    "Last name new: {%contact.last_name%}\r\n" +
                    "Middle name new: {%contact.middle_name%}\r\n" +
                    "Date new: {%date%}\r\n" +
                    "Assignee new: {%ticket.assigned_to%}\r\n" +
                    "Issue ID new: {%ticket.id%}\r\n" +
                    "Issue tracker new: {%ticket.tracker%}\r\n" +
                    "Issue description new: {%ticket.quoted_description%}\r\n" +
                    "Project new: {%ticket.project%}\r\n" +
                    "Subject new: {%ticket.subject%}\r\n" +
                    "Note author new: {%response.author%}\r\n" +
                    "Note author first name new: {%response.author.first_name%}\r\n" +
                    "Issue Status: {%ticket.status%}\r\n" +
                    "Issue Priority: {%ticket.priority%}\r\n" +
                    "Issue public url: {%ticket.public_url%}\r\n" +
                    "Issue Estimated hours: {%ticket.estimated_hours%}\r\n" +
                    "Issue Done ratio: {%ticket.done_ratio%}\r\n"

    journal.save!
    User.current = User.find(4)

    ContactsSetting[:helpdesk_emails_header, Project.find('ecookbook').id] = "Hello old, %%NAME%%\r\nHello new, {%contact.first_name%}"
    ContactsSetting[:helpdesk_emails_footer, Project.find('ecookbook').id] = "Regards old, %%NOTE_AUTHOR.FIRST_NAME%%\r\nRegards new, {%response.author.first_name%}"
    assert HelpdeskMailer.issue_response(contact, journal, params = {}).deliver
    mail_body = last_email.text_part.body.to_s
    assert_match /Hello old, Ivan/,  mail_body
    assert_match /Full name old: Ivan Ivanov/,  mail_body
    assert_match /Company old: Domoway/,  mail_body
    assert_match /Last name old: Ivanov/,  mail_body
    assert_match /Middle name old: Ivanovich/,  mail_body
    assert_match /Assignee old: Robert Hill/,  mail_body
    assert_match /Issue ID old: 1/,  mail_body
    assert_match /Issue tracker old: Bug/,  mail_body
    assert_match /Issue description old: > Unable to print recipes/,  mail_body
    assert_match /Project old: eCookbook/,  mail_body
    assert_match /Subject old: Can't print recipes/,  mail_body
    assert_match /Note author old: John Smith/,  mail_body
    assert_match /Note author first name old: John/,  mail_body
    assert_match /Regards old, John/,  mail_body

    assert_match /Hello new, Ivan/,  mail_body
    assert_match /Full name new: Ivan Ivanov/,  mail_body
    assert_match /Company new: Domoway/,  mail_body
    assert_match /Last name new: Ivanov/,  mail_body
    assert_match /Middle name new: Ivanovich/,  mail_body
    assert_match /Assignee new: Robert Hill/,  mail_body
    assert_match /Issue ID new: 1/,  mail_body
    assert_match /Issue tracker new: Bug/,  mail_body
    assert_match /Issue description new: > Unable to print recipes/,  mail_body
    assert_match /Project new: eCookbook/,  mail_body
    assert_match /Subject new: Can't print recipes/,  mail_body
    assert_match /Note author new: John Smith/,  mail_body
    assert_match /Note author first name new: John/,  mail_body
    assert_match /Regards new, John/,  mail_body
    assert_match /Issue Status: New/, mail_body
    assert_match /Issue Priority: Low/, mail_body

    assert_match "Issue public url: http:\/\/mydomain.foo\/tickets\/1\/#{issue.helpdesk_ticket.token}", mail_body
    assert_match /Issue Estimated hours: 12.0/, mail_body
    assert_match /Issue Done ratio: 50/, mail_body

  end

  test "Should send from changed address" do
    issue = Issue.find(1)
    contact = Contact.find(1)
    ContactsSetting[:helpdesk_answer_from, issue.project.id] = "newfrom@mail.com"

    assert HelpdeskMailer.issue_response(contact, issue.journals.last, params = {}).deliver
    assert last_email.to.include?(contact.emails.first)
    assert last_email.subject.include?("[#{issue.tracker} ##{issue.id}]")
    assert_equal "newfrom@mail.com", last_email.from.first.to_s
  end

  test "Should send to changed address" do
    issue = Issue.find(1)
    contact = Contact.find(1)

    assert HelpdeskMailer.issue_response(contact, issue.journals.last, params = {:helpdesk => {:to_address => "to_address@mail.com"}}).deliver
    assert_equal "to_address@mail.com", last_email.to_addrs.first.to_s
  end

  test "Should find issue by in_reply_to" do
    issue = Issue.find(1)
    journal = issue.journals.last
    contact = Contact.find(1)
    journal.journal_message = JournalMessage.new(:contact => contact,
                                                 :journal => issue.journals.last,
                                                 :from_address => contact.primary_email,
                                                 :message_date => Time.now,
                                                 :message_id => '123456789@mail.com')
    journal.save!
    response_journal = submit_helpdesk_email('ticket_with_in_reply_to.eml', :issue => {:project_id => 'ecookbook'}, :reopen_status => 'Feedback')
    assert_equal Journal, response_journal.class
    assert_equal response_journal.issue, journal.issue
  end

  test "Should add journal with empty status settings" do
    issue = Issue.find(1)
    journal = issue.journals.last
    contact = Contact.find(1)
    journal.journal_message = JournalMessage.new(:contact => contact,
                                                 :journal => issue.journals.last,
                                                 :from_address => contact.primary_email,
                                                 :message_date => Time.now,
                                                 :message_id => '123456789@mail.com')
    journal.save!
    response_journal = submit_helpdesk_email('ticket_with_in_reply_to.eml', :issue => {:project_id => 'ecookbook'}, :reopen_status => "")
    assert_equal Journal, response_journal.class
    assert_equal response_journal.issue, journal.issue
    assert_equal issue.status_id, response_journal.issue.status_id
  end

end
