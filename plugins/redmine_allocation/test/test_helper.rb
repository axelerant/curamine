# Load the normal Rails helper
require File.expand_path('../../../../test/test_helper', File.dirname(__FILE__))

require File.dirname(__FILE__) + "/functional/allocation_controller_test_case.rb"

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

gem 'mocha'
require 'mocha'

def create_test_data
  # Project
  p = Project.new(:identifier => "allocation",
                  :name       => "allocation test",
                  :is_public  => false,
                  :enabled_module_names => ["issue_tracking"])
  p.save!
  # Member
  m = Member.new(:user => User.find_by_login("admin"),
                 :roles => [Role.find_by_name("Manager")],
                 :project => p,
                 :from_date => "2012-01-01",
                 :to_date => "2012-06-01")
  m.save!
end
