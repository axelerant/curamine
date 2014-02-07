require File.expand_path('../../test_helper', __FILE__)

# Re-raise errors caught by the controller.
# class HelpdeskMailerController; def rescue_action(e) raise e end; end

class IssuesControllerTest < ActionController::TestCase
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
    RedmineHelpdesk::TestCase.prepare

    @controller = IssuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_show_issue
    issue = Issue.find(1)
    assert_not_nil issue.helpdesk_ticket
    get :show, :id => 1
    assert_response :success
  end

  def test_should_send_note
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = user.id
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :issue => {:notes => notes}
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = ActionMailer::Base.deliveries.last
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
  end

  def test_should_send_note_with_bcc
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1, :is_cc => 1, :bcc_list => "mail1@mail.com, mail2@mail.com"},
         :issue => {:notes => notes}
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = ActionMailer::Base.deliveries.last
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
    assert_equal ["mail1@mail.com", "mail2@mail.com"].sort, mail.bcc.sort
  end

  def test_should_not_send_note_with_cc
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1,
                       :bcc_list => "",
                       :is_cc => 1,
                       :cc_list => "mail3@mail.com, mail4@mail.com"},
         :issue => {:notes => notes}
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = ActionMailer::Base.deliveries.last
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
    assert_equal ["mail3@mail.com", "mail4@mail.com"].sort, mail.cc.sort
    assert mail.bcc.empty?, "Bcc should be empty"
  end

  def test_should_send_note_issue_from_anonymous
    issue = Issue.find(1)
    issue.author_id = 6
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = ActionMailer::Base.deliveries.last
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
  end

  def test_should_create_ticket
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    assert_difference 'HelpdeskTicket.count' do
      post :create,
           :helpdesk_ticket => {:contact_id => 1, :source => "0", :ticket_date => "2013-01-01 01:01:01 +0400"},
           :issue => {:tracker_id => 3, :subject => "test", :status_id => 2, :priority_id => 5},
           :project_id => 1
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
    assert_not_nil Issue.last.helpdesk_ticket
  end

  def test_should_send_auto_answer
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    assert_difference 'HelpdeskTicket.count' do
      post :create,
           :helpdesk_ticket => {:contact_id => 1, :source => "0", :ticket_date => "2013-01-01 01:01:01 +0400"},
           :issue => {:tracker_id => 3, :subject => "test", :status_id => 2,
                      :priority_id => 5, :description => "test description"},
           :helpdesk_send_auto_answer => 1,
           :project_id => 1
    end
    mail = ActionMailer::Base.deliveries.last
    assert_mail_body_match "We hereby confirm that we have received your message", mail
  end

  def test_should_not_create_ticket_for_invalid_issue
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    ActionMailer::Base.deliveries.clear
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :issue => { :notes => 'Test notes', :subject => '' }
    assert_blank ActionMailer::Base.deliveries
  end

  def test_should_not_create_ticket_with_empty_customer
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    assert_no_difference 'HelpdeskTicket.count' do
      post :create,
           :helpdesk_ticket => {:source => "0", :contact_id => '', :ticket_date => "2013-01-01 01:01:01 +0400"},
           :issue => {:tracker_id => 3, :subject => "Test subject", :status_id => 2, :priority_id => 5},
           :project_id => 1
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
    assert_nil Issue.last.helpdesk_ticket
  end

end
