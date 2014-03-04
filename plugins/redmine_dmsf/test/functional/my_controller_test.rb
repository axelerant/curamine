# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2013   Karel Picman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class MyControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n
  
  fixtures :users, :user_preferences

  def setup
    @request.session[:user_id] = 2
  end 
  
  def test_page_with_open_approvals_block
    preferences = User.find(2).pref
    preferences[:my_page_layout] = {'top' => ['open_approvals']}
    preferences.save!
    
    get :page
    assert_response :success    
    assert_select 'h3', {:text => "#{l(:label_my_open_approvals)} (2)"}
  end
  
  def test_page_with_open_locked_documents
    preferences = User.find(2).pref
    preferences[:my_page_layout] = {'top' => ['locked_documents']}
    preferences.save!
    
    get :page
    assert_response :success
    assert_select 'h3', {:text => "#{l(:label_my_locked_documents)} (0/1)"}
  end
end
