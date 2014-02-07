require File.expand_path('../../test_helper', __FILE__)

# Re-raise errors caught by the controller.
# class HelpdeskMailerController; def rescue_action(e) raise e end; end

class HelpdeskMailerControllerTest < ActionController::TestCase
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
                            [:journal_messages])

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/helpdesk_mailer'

  def setup
    RedmineHelpdesk::TestCase.prepare

    @controller = HelpdeskMailerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_should_create_issue
    # Enable API and set a key
    Setting.mail_handler_api_enabled = 1
    Setting.mail_handler_api_key = 'secret'

    post :index, :key => 'secret', :issue => {:project_id => 'ecookbook', :status => 'Closed', :tracker => 'Bug', :assigned_to => 'jsmith'}, :email => IO.read(File.join(FIXTURES_PATH, 'new_issue_new_contact.eml'))
    assert_response 201
    assert_not_nil Contact.find_by_first_name('New')
  end

  def test_should_get_mail
    # Enable API and set a key
    Setting.mail_handler_api_enabled = 1
    Setting.mail_handler_api_key = 'secret'

    post :get_mail, :key => 'secret'
    assert_response :ok
  end

end
