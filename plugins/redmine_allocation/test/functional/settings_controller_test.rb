require File.dirname(__FILE__) + "/../test_helper"

class SettingsControllerTest < AllocationControllerTestCase
  test "settings page shows fields to configure user and projects custom fields" do
    admin_login
    get :plugin, :id => "redmine_allocation"
    assert_response :success

    assert_select "select[name=?]", "settings[users_custom_field]"
    assert_select "select[name=?]", "settings[projects_custom_field]"
  end
end
