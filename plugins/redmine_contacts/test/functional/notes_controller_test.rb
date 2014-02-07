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

require File.expand_path('../../test_helper', __FILE__)

class NotesControllerTest < ActionController::TestCase
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
                            [:contacts,
                             :contacts_projects,
                             :contacts_issues,
                             :deals,
                             :notes,
                             :tags,
                             :taggings,
                             :contacts_queries])

  def setup
    RedmineContacts::TestCase.prepare

    @controller  = NotesController.new
    @request     = ActionController::TestRequest.new
    @response    = ActionController::TestResponse.new
    User.current = nil
    @request.env['HTTP_REFERER'] = '/'
  end

  test "should post add note to contact" do
    @request.session[:user_id] = 1
    assert_difference 'Note.count' do
      post :create, :project_id => 1,
                    :note => {
                                :subject => "Note subject",
                                :content => "Note *content*"},
                    :source_type => Contact.to_s,
                    :source_id => 1

    end

    note = Note.find(:first, :conditions => {:subject => "Note subject", :content => "Note *content*"})
    assert_not_nil note
    assert_equal 1, note.source_id
    assert_equal Contact, note.source.class
  end

  test "should put update" do
    @request.session[:user_id] = 1

    note = Note.find(1)
    old_content = note.content
    new_content = 'New note content'

    put :update, :id => 1, :project_id => 1, :note => {:content => new_content}
    assert_redirected_to :action => 'show', :project_id => note.source.project, :id => note.id
    note.reload
    assert_equal new_content, note.content

  end

end
