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

class DealProcess < ActiveRecord::Base
  unloadable

  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :deal
  belongs_to :from, :class_name => "DealStatus", :foreign_key => "old_value"
  belongs_to :to, :class_name => "DealStatus", :foreign_key => "value"
  scope :visible, lambda {|*args| { :include => {:deal => :project},
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_deals)} }

  def self.status_funnel_data(status, options={})

    deals = if status.blank?
      Deal.visible.closed.includes(:deal_processes).uniq
    elsif status.is_open?
      Deal.visible.closed.was_in_status(status.id)
    else
      Deal.visible.includes(:deal_processes).where(:status_id => status.id).uniq
    end

    deals = deals.where(["#{Deal.table_name}.project_id = ?", options[:project_id]]) unless options[:project_id].blank?
    deals = deals.where(["#{Deal.table_name}.category_id = ?",  options[:category_id]]) unless options[:category_id].blank?
    deals = deals.where(["#{Deal.table_name}.author_id = ?", options[:author_id]]) unless options[:author_id].blank?
    deals = deals.where(["#{Deal.table_name}.assigned_to_id = ?", options[:assigned_to_id]]) unless options[:assigned_to_id].blank?
    deals = deals.where(["((#{DealProcess.table_name}.created_at BETWEEN ? AND ?) OR (#{Deal.table_name}.created_on BETWEEN ? AND ?))", options[:from], options[:to], options[:from], options[:to]]) unless options[:from].blank? || options[:to].blank?

    deals_count = deals.uniq.map.count
    # deals_lost = deals.lost.pluck("#{Deal.table_name}.id").count
    deals_sum = {}
    deals.map.group_by{|d| d.currency}.each{|k, v| deals_sum[k] = v.sum{|d| d.price.to_f} }
    {:count => deals_count, :sum => deals_sum}
  end

end
