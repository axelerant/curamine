# encoding: utf-8
#
# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2015 RedmineCRM
# http://www.redminecrm.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

def with_agile_settings(options, &block)
  saved_settings = options.keys.inject({}) do |h, k|
    h[k] = case Setting.plugin_redmine_agile[k]
      when Symbol, false, true, nil
        Setting.plugin_redmine_agile[k]
      else
        Setting.plugin_redmine_agile[k].dup
      end
    h
  end
  options.each {|k, v| Setting.plugin_redmine_agile[k] = v}
  yield
ensure
  saved_settings.each {|k, v| Setting.plugin_redmine_agile[k] = v} if saved_settings
end

def log_user(login, password)
  User.anonymous
  get "/login"
  assert_equal nil, session[:user_id]
  assert_response :success
  assert_template "account/login"
  post "/login", :username => login, :password => password
  assert_equal login, User.find(session[:user_id]).login
end

def credentials(user, password=nil)
  {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user, password || user)}
end

module RedmineAgile
  module Demo
    # create_issue(10.days.ago, 4.days.ago, version)
    # 100.times{|i| create_issue(100.days.ago + i, 90.days.ago + i, version)}
    class << self
      def create_issue(from, to, options={})
        version = options[:version] || Version.last
        tracker = options[:tracker] || version.project.trackers.select{|t| t.issue_statuses.any?}.sample
        return false unless tracker
        status = options[:status] || tracker.issue_statuses.sample
        issue = Issue.create(:subject => "New issue #{rand(1000)}",
                          :fixed_version => version,
                          :project => version.project,
                          :tracker => tracker,
                          :start_date => from,
                          :created_on => from,
                          :updated_on => to,
                          :due_date => to,
                          :closed_on => (status.is_closed? ? to : nil),
                          :status => status,
                          :author => version.project.members.map(&:user).flatten.sample)
      end

      def change_issue_done_ratio(issue, change_date, value)
        # journal = issue.init_journal(User.current)
        issue.done_ratio = value
        issue.save
        issue.update_attributes(:updated_on => change_date)
        Journal.last.update_attributes(:created_on => change_date)
      end

      def close_issue(issue, closed_on)
        journal = issue.init_journal(User.current)
        done_status = IssueStatus.where(:name => "Closed", :is_closed => true).first
        in_status = IssueStatus.where(:name => "In progress", :is_closed => false)
        days_count = (issue.due_date - issue.created_on).to_i
        change_date = issue.created_on
        change_date = change_date + rand((issue.due_date - days_count).to_i)
        issue.update_attributes(:status_id => in_status.id, :updated_on => change_date)
        journal.update_attributes(:created_on => change_date)
        change_date = change_date + rand((issue.due_date - days_count).to_i)
        issue.update_attributes(:status_id => done_status.id, :updated_on => change_date)
        journal.update_attributes(:created_on => change_date)
        issue
      end

      def create_version_issue(from, to, version, done_ratio=[])
        to = from + 1 if to < from
        issue = create_issue(from, to, :version => version, :status => IssueStatus.where(:name => "New", :is_closed => false).first)
        days_count = (to - from).to_i
        if done_ratio.empty?
          change_issue_done_ratio(issue, from + rand(days_count), rand(100))
          change_issue_done_ratio(issue.reload, to.to_time - 2.hours , 100)
        else
          change_date = from
          done_ratio.each do |ratio|
            change_date = change_date + rand((to - change_date).to_i)
            change_issue_done_ratio(issue, change_date, ratio)
          end
        end
      end

      # create_version_issue("2012-03-10".to_date, "2012-03-14".to_date, version)
      # create_version_issue("2012-03-10".to_date, "2012-03-14".to_date, version, done_ratio=[30, 100])

    end
  end
end
