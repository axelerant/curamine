# encoding: utf-8
#
# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class DealsControllerTest < ActionController::TestCase
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

    ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/',
                            [:roles,
                             :enabled_modules,
                             :contacts,
                             :contacts_projects,
                             :contacts_issues,
                             :deals,
                             :deal_statuses,
                             :deal_statuses_projects,
                             :notes,
                             :tags,
                             :taggings,
                             :contacts_queries])

  def setup
    RedmineContacts::TestCase.prepare

    @controller = DealsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  test "should get index" do
    @request.session[:user_id] = 1

    get :index
    assert_response :success
    assert_template :index
    assert_template :partial => '_list_excerpt'
    assert_not_nil assigns(:deals)
    assert_nil assigns(:project)
    assert_select 'a', /First deal with contacts/
  end

  test "should get index list" do
    @request.session[:user_id] = 1

    get :index, :deals_list_style => 'list'
    assert_response :success
    assert_template :partial => '_list'
    assert_not_nil assigns(:deals)
    assert_nil assigns(:project)
    assert_select 'a', /First deal with contacts/
  end

  test "should get index board" do
    @request.session[:user_id] = 1

    get :index, :deals_list_style => 'list_board'
    assert_response :success
    assert_template :partial => '_list_board'
    assert_not_nil assigns(:deals)
    assert_nil assigns(:project)
    assert_select 'a', /First deal with contacts/
  end

  test "should get index board with sorting" do
    @request.session[:user_id] = 1

    get :index, :deals_list_style => 'list_board', :sort => 'due_date'
    assert_response :success
    assert_template :partial => '_list_board'
    assert_not_nil assigns(:deals)
    assert_nil assigns(:project)
    assert_select 'a', /First deal with contacts/
  end

  test "should get index without statuses" do
    @request.session[:user_id] = 1

    DealStatus.delete_all

    get :index
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:deals)
    assert_nil assigns(:project)
    assert_equal 5, assigns(:deals).count

    get :index, :status_id => ''
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:deals)
    assert_nil assigns(:project)
    assert_equal 5, assigns(:deals).count
  end

  test "should not get closed in index" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1

    get :index
    assert_response :success
    assert_template :index
    assert_select 'a', /First deal with contacts/
    assert_select 'table.contacts.index h1.deal_name a', {:count => 0, :text => /Closed deal/}
  end

  test "should get closed index with pages" do
    # log_user('admin', 'admin')
    # debugger
    @request.session[:user_id] = 1
    per_page_options = Setting.per_page_options
    Setting.per_page_options = 1

    get :index, :page => 2, :per_page => 1, :status_id => "", :sort => "name"
    assert_response :success
    assert_template :index
    assert_select 'table.contacts.index h1.deal_name a', /Deal without contact/
    assert_select 'table.contacts.index h1.deal_name a', {:count => 0, :text => /First deal with contacts/}

    Setting.per_page_options = per_page_options
  end

  test "should get index with filters" do
    @request.session[:user_id] = 1

    get :index
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:deals)
    assert_nil assigns(:project)

    get :index, :status_id => ""
    assert_equal 5, assigns(:deals).count
    assert_select 'table.contacts.index h1.deal_name a', /First deal with contacts/
    assert_select 'table.contacts.index h1.deal_name a', /Deal without contact/
    assert_select 'table.contacts.index h1.deal_name a', /Delevelop redmine plugin/

    get :index, :status_id => "2"
    assert_equal 2, assigns(:deals).count
    assert_select 'table.contacts.index h1.deal_name a', /Delevelop redmine plugin/
    assert_select 'table.contacts.index h1.deal_name a', {:count => 0, :text => "Second deal with contacts"}

    get :index, :assigned_to_id => "1"
    assert_equal 1, assigns(:deals).count
    assert_select 'table.contacts.index h1.deal_name a', /First deal with contacts/
  end

  test "should get index with project" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 3

    get :index, :project_id => 1
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:deals)
    assert_not_nil assigns(:project)
    assert_tag :tag => 'a', :content => /First deal with contacts/
    assert_no_tag :tag => 'a', :content => /Second deal with contacts/
    assert_tag :tag => 'h3', :content => /Recently viewed/
    # private projects hidden
    # assert_no_tag :tag => 'a', :content => /Issue of a private subproject/
    # assert_no_tag :tag => 'a', :content => /Issue on project 2/
    # project column
    # assert_tag :tag => 'th', :content => /Project/
  end

  test "should get project index without statuses" do
    project = Project.find_by_identifier('onlinestore')

    @request.session[:user_id] = 1
    get :index, :project_id => 'onlinestore'
    assert_response :success
    assert_template 'index'
    assert_equal 1, assigns(:deals).count

    assert_select '.filter-condition #status_id'
    assert_select 'table.deals_statistics'
    assert_tag :tag => 'a', :content => /Deal without contact/


    project.deal_statuses.delete_all

    @request.session[:user_id] = 1
    get :index, :project_id => 'onlinestore'
    assert_response :success
    assert_template 'index'
    assert_equal 4, assigns(:deals).count

    assert_select '.filter-condition #status_id', {:count => 0}
    assert_select 'table.deals_statistics', {:count => 0}
    assert_tag :tag => 'a', :content => /Deal without contact/
  end

  test "should post create" do
    @request.session[:user_id] = 1
    assert_difference 'Deal.count' do
      post :create, :project_id => 1,
                    :deal => {:price => 5500,
                              :name => "New created deal 1",
                              :background =>"Background of new created deal",
                              :contact_id => 2,
                              :assigned_to_id => 3,
                              :category_id => 1,
                              :probability => 30,
                              :currency => 'RUB'}

    end
    assert_redirected_to :controller => 'deals', :action => 'show', :id => Deal.last.id

    deal = Deal.find_by_name('New created deal 1')
    assert_not_nil deal
    assert_equal 1, deal.category_id
    assert_equal 2, deal.contact_id
    assert_equal 3, deal.assigned_to_id
    assert_equal 30, deal.probability
    assert_equal 'RUB', deal.currency
  end

  test "should get show" do
    @request.session[:user_id] = 1
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:deal)
    assert_equal Deal.find(1), assigns(:deal)
  end

  test "should get show with statuses" do
    project = Project.find(1)
    project.deal_statuses.delete_all
    project.deal_statuses << DealStatus.find(1)
    project.deal_statuses << DealStatus.find(2)
    project.save

    assert_equal ['Pending', 'Won', 'Lost'].sort, DealStatus.all.map(&:name).sort
    assert_equal ['Pending', 'Won'].sort, project.deal_statuses.map(&:name).sort
    @request.session[:user_id] = 1
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_select '#deal_status_id', /Pending/
    assert_select '#deal_status_id', /Won/
    assert_select '#deal_status_id', {:count => 0, :text => /Lost/}
  end

  test "should get new" do
    @request.session[:user_id] = 1

    project = Project.find(1)
    project.deal_statuses << DealStatus.default
    project.save

    get :new, :project_id => 1
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:deal)
    assert_equal DealStatus.default, assigns(:deal).status
    assert_equal ContactsSetting.default_currency, assigns(:deal).currency
  end

  test "index should not contatin add deal link" do
    EnabledModule.where(:name => 'deals').delete_all

    @request.session[:user_id] = 1
    get :index
    assert_response :success
    assert_select '[href="/deals/new"]', {:count => 0}
  end

  test "should get edit" do
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:deal)
    assert_equal Deal.find(1), assigns(:deal)
  end

  test "should put update" do
    @request.session[:user_id] = 1
    Setting.plugin_redmine_contacts["thousands_delimiter"] = ','
    Setting.plugin_redmine_contacts["decimal_separator"] = '.'

    deal = Deal.find(1)
    old_name = deal.name
    new_name = 'Name modified by DealControllerTest#test_put_update'

    put :update, :id => 1, :deal => {:name => new_name, :currency => "GBP", :price => 23000}
    assert_redirected_to :action => 'show', :id => '1'
    deal.reload
    assert_equal 23000, deal.price

    get :show, :id => 1
    assert_response :success
    assert_select 'td.subject_info', "£23,000.00"

    assert_equal new_name, deal.name
  end

  test "should bulk edit deals" do
    @request.session[:user_id] = 1
    post :bulk_edit, :ids => [1, 2, 4]
    assert_response :success
    assert_template 'bulk_edit'
    assert_not_nil assigns(:deals)
  end

  test "should not bulk edit deals by deny user" do
    @request.session[:user_id] = 4
    post :bulk_edit, :ids => [1, 2, 4]
    assert_response 403
  end

  test "should put bulk update " do
    @request.session[:user_id] = 1

    put :bulk_update, :ids => [1, 2, 4],
                      :deal => {:assigned_to_id => 2,
                                :category_id => 2,
                                :currency => 'GBP'},
                      :note => {:content => "Bulk deals edit note content"}

    assert_redirected_to :controller => 'deals', :action => 'index', :project_id => nil

    deals = Deal.find(1, 2, 4)

    assert_equal [2], deals.collect(&:assigned_to_id).uniq
    assert_equal [2], deals.collect(&:category_id).uniq
    assert_equal ['GBP'], deals.collect(&:currency).uniq

    assert_equal 3, Note.count(:conditions =>  {:content => "Bulk deals edit note content"})
  end

  test "should delete bulk destroy " do
    @request.session[:user_id] = 1
    delete :bulk_destroy, :ids => [1, 2, 4]
    assert_redirected_to :controller => 'deals', :action => 'index'
  end

  test "should post index live search" do
    @request.session[:user_id] = 1
    xhr :post, :index, :search => "First", :period => "all", :assigned_to_id => "", :status_id => "o"
    assert_response :success
    assert_template '_list'
    assert_tag :tag => 'a', :content => /First deal with contacts/
  end

  test "should post index live search in project" do
    @request.session[:user_id] = 1
    xhr :post, :index, :search => "First", :project_id => 'ecookbook'
    assert_response :success
    assert_template '_list'
    assert_tag :tag => 'a', :content => /First deal with contacts/
  end

  test "should get index as csv" do
    field = DealCustomField.create!(:name => 'Test custom field', :is_filter => true, :field_format => 'string')
    deal = Deal.find(1)
    deal.custom_field_values = {field.id => "This is custom значение"}
    deal.save
    @request.session[:user_id] = 1
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:deals)
    assert_equal "text/csv; header=present", @response.content_type
    assert_match "Test custom field", @response.body
    assert_match "This is custom значение", @response.body
  end


end
