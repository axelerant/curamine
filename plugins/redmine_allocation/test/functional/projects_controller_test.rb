require File.dirname(__FILE__) + "/../test_helper"

class ProjectsControllerTest < AllocationControllerTestCase
  test "project members page shows allocation fields" do
    admin_login
    get :settings, :id => "allocation"
    assert_response :success

    assert_select "#tab-content-members table.members thead th", :count => 1, :html => I18n.t(:field_allocation)
    assert_select "#tab-content-members table.members thead th", :count => 1, :html => I18n.t(:field_from_date)
    assert_select "#tab-content-members table.members thead th", :count => 1, :html => I18n.t(:field_to_date)
  end

  test "overview sidebar shows a link to allocation info" do
    admin_login
    get :show, :id => "allocation"
    assert_response :success

    assert_select "div#sidebar a", :count => 1, :text => I18n.t(:"allocation.label_by_project")
    assert_select "div#sidebar a", :count => 1, :text => I18n.t(:"allocation.label_by_user")
  end
end
