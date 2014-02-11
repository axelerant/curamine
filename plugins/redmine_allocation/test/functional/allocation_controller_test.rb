require File.dirname(__FILE__) + "/../test_helper"

class AllocationControllerTest < AllocationControllerTestCase
  test "active project tab is overview" do
    admin_login
    get :by_project, :id => "allocation"
    assert_response :success

    assert_select "a.overview.selected"
  end

  test "allocation by project page shows a link to allocation info in the sidebar" do
    admin_login
    get :by_project, :id => "allocation"
    assert_response :success

    assert_select "div#sidebar a", :count => 1, :text => I18n.t(:"allocation.label_by_project")
    assert_select "div#sidebar a", :count => 1, :text => I18n.t(:"allocation.label_by_user")
  end

  test "allocation by project page shows a table with allocation data" do
    admin_login
    get :by_project, :id => "allocation"
    assert_response :success

    assert_select "tbody tr", :count => 1
    assert_select "tbody tr td:nth-child(1)", :text => User.find_by_login("admin").to_s
    assert_select "tbody tr td:nth-child(2)", :text => "0 %"
    assert_select "tbody tr td:nth-child(3)", :text => "01/01/2012"
    assert_select "tbody tr td:nth-child(4)", :text => "06/01/2012"
  end
end
