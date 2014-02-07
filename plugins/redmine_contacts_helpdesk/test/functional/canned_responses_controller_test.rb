require File.expand_path('../../test_helper', __FILE__)

class CannedResponsesControllerTest < ActionController::TestCase
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
    @request.session[:user_id] = 1
    # @response   = ActionController::TestResponse.new
  end

  def test_should_get_new
    get :new, :project_id => 1
    assert_response 200
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response 200
  end

  def test_should_post_create
    post :create, :canned_response => {:name => "New canned response", :content => "Hi there!", :is_public => false}, :project_id => 1
    assert_redirected_to settings_project_path(Project.find('ecookbook'), :tab => 'helpdesk_canned_responses')
    assert_equal "New canned response", CannedResponse.last.name
  end

  def test_should_put_update
    put :update, :id => 1, :canned_response => {:name => "New name"}
    assert_redirected_to settings_project_path(Project.find('ecookbook'), :tab => 'helpdesk_canned_responses')
    assert_equal "New name", CannedResponse.find(1).name
  end

  def test_should_delete_destroy
    delete :destroy, :id => 1
    assert_redirected_to settings_project_path(Project.find('ecookbook'), :tab => 'helpdesk_canned_responses')
    assert_nil CannedResponse.find_by_id(1)
  end  

  def test_should_get_add
    xhr :get, :add, :id => 1, :project_id => 1, :issue_id => 1
    assert_response 200
  end  

end
