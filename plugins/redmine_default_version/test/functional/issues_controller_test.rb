require File.dirname(__FILE__) + '/../test_helper'

class IssuesControllerTest < ActionController::TestCase
  fixtures :projects, :issues, :users, :trackers, :issue_statuses

  def setup
    @request.session[:user_id] = 2
    User.stubs(:current).returns(User.find_by_id(2))
    User.any_instance.stubs(:allowed_to?).returns(true)
    Mailer.stubs(:deliver_mail).returns(true)
  end

  def test_can_get_bulk_edit_on_different_projects
    get :bulk_edit, :ids => Issue.all.map(&:id)
    assert_response :success
  end

  def test_can_get_bulk_edit_on_same_project
    get :bulk_edit, :ids => Project.first.issues.map(&:id)
    assert_response :success
  end
end
