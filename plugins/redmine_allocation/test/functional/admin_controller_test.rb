require File.dirname(__FILE__) + "/../test_helper"

class AdminControllerTest < AllocationControllerTestCase
  test "plugin show a configure link in administration, plugins" do
    admin_login
    get :plugins
    assert_response :success

    assert_select "td.configure" do
      assert_select 'a[href="/settings/plugin/redmine_allocation"]'
    end
  end
end
