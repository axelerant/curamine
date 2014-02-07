require File.expand_path('../../test_helper', __FILE__)

class PublicTicketsControllerTest < ActionController::TestCase

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

  def setup
    RedmineHelpdesk::TestCase.prepare
    RedmineHelpdesk.settings[:helpdesk_public_tickets] = 1
    @request.session[:user_id] = User.anonymous.id
    # @response   = ActionController::TestResponse.new
  end

  def test_should_show_issue_with_correct_hash
    get :show, :id => 1, :hash => HelpdeskTicket.first(:order => 'id ASC').token
    assert_response 200
  end

  def test_should_show_404_with_incorrect_hash
    get :show, :id => 1, :hash => '123'
    assert_response 404
  end

  def test_should_show_404_with_public_deny
    RedmineHelpdesk.settings[:helpdesk_public_tickets] = 0
    get :show, :id => 1, :hash => HelpdeskTicket.first(:order => 'id ASC').token
    assert_response 404
  end

  def test_should_show_creator_email
    get :show, :id => 1, :hash => HelpdeskTicket.first(:order => 'id ASC').token
    assert_select "p.author", /#{HelpdeskTicket.first.from_address}/
  end

  def test_should_add_comment
    RedmineHelpdesk.settings[:helpdesk_public_comments] = 1
    ticket = HelpdeskTicket.find(1)
    get :add_comment, :id => 1, :hash => ticket.token, :journal => {:notes => "Test public comment"}
    assert_equal "Test public comment", Journal.first(:order => 'id DESC').notes
    assert_equal Journal.first(:order => 'id DESC').created_on.to_s, JournalMessage.first(:order => 'id DESC').message_date.to_s
    get :show, :id => 1, :hash => ticket.token
    assert_select ".journal .wiki p", /Test public comment/
  end

  def test_should_change_status
    RedmineHelpdesk.settings[:helpdesk_public_comments] = 1
    ContactsSetting[:helpdesk_reopen_status, HelpdeskTicket.first(:order => 'id ASC').issue.project_id] = IssueStatus.last(:order => 'id DESC').id
    get :add_comment, :id => 1, :hash => HelpdeskTicket.first(:order => 'id ASC').token, :journal => {:notes => "Test public comment"}
    assert_equal IssueStatus.last(:order => 'id DESC'), Journal.last(:order => 'id DESC').issue.status
  end

  def test_should_not_add_comment_if_deny
    RedmineHelpdesk.settings[:helpdesk_public_comments] = 0
    get :add_comment, :id => 1, :hash => HelpdeskTicket.first.token, :journal => {:notes => "Test comment"}
    assert_response 404
  end

  def test_should_show_followups
    @request.session[:user_id] = 1
    journal = HelpdeskTicket.first(:order => 'id ASC').issue.journals.create(:journalized_type => 'Issue', :notes => 'Followup1')
    journal_message = journal.create_journal_message(:contact =>  Contact.first(:order => 'id ASC'), :is_incoming => true, :from_address => Contact.first(:order => 'id ASC').email, :message_date => Time.now)
    assert journal_message.valid?
    get :show, :id => 1, :hash => HelpdeskTicket.first(:order => 'id ASC').token
    assert_select ".journal h4", /#{Contact.first(:order => 'id ASC').email}/
  end

end