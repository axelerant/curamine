require File.expand_path('../../test_helper', __FILE__)

class CommonViewsTest < ActionController::IntegrationTest
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
                                          :canned_responses,
                                          :helpdesk_tickets])

  def setup
    RedmineHelpdesk::TestCase.prepare

    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env['HTTP_REFERER'] = '/'
  end

  test "View project settings" do
    log_user("admin", "admin")
    get "/projects/ecookbook/settings"
    assert_response :success
  end

  test "View helpdesk plugin settings" do
    log_user("admin", "admin")
    get "/settings/plugin/redmine_contacts_helpdesk"
    assert_response :success
  end

end
