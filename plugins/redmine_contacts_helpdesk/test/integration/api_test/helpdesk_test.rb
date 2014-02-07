require File.expand_path('../../../test_helper', __FILE__)
# require File.dirname(__FILE__) + '/../../../../../test/test_helper'

class Redmine::ApiTest::HelpdeskTest < Redmine::ApiTest::Base
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
    Setting.rest_api_enabled = '1'
    RedmineHelpdesk::TestCase.prepare
  end

  test "POST /helpdesk/email_note.xml" do
    # Issue.find(1).contacts << Contact.find(1)
    Redmine::ApiTest::Base.should_allow_api_authentication(:post,
                                    '/helpdesk/email_note.xml',
                                    {:message => {:issue_id => 1, :content => 'Test note', :status_id => 3}},
                                    {:success_code => :created})

    assert_difference('Journal.count') do
      post '/helpdesk/email_note.xml', {:message => {:issue_id => 1, :content => 'Test note', :status_id => 3}}, credentials('admin')
    end
    assert_response :created

    journal = Journal.first(:order => 'id DESC')
    assert_equal 'Test note', journal.notes

    assert_equal 'application/xml', @response.content_type
    assert_tag 'message', :child => {:tag => 'journal_id', :content => journal.id.to_s}
  end

  test "POST /helpdesk/create_ticket.xml" do
    params = {:ticket => {:issue => {:project_id => 1, :subject => 'API test',
                                     :tracker_id => 2, :status_id => 3, :description => 'Ticket body'},
                          :contact => {:first_name => 'API Contact', :email => 'api@contact.mail'}}}
    Redmine::ApiTest::Base.should_allow_api_authentication(:post,
                                    '/helpdesk/create_ticket.xml',
                                    params,
                                    {:success_code => :created})
    assert_difference('Issue.count') do
      post '/helpdesk/create_ticket.xml',
           params, credentials('admin')
    end
    issue = Issue.first(:order => 'id DESC')
    assert_equal 1, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal 3, issue.status_id
    assert_equal 'Ticket body', issue.description
    assert_equal 'API test', issue.subject

    contact = issue.customer
    assert_equal 'API Contact', contact.first_name

    assert_response :created
    assert_equal 'application/xml', @response.content_type
    assert_match  /Issue \d+ created/, @response.body
  end

end
