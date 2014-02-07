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

class DealStatus < ActiveRecord::Base
  unloadable

  OPEN_STATUS = 0
  WON_STATUS = 1
  LOST_STATUS = 2

  before_destroy :check_integrity

  has_and_belongs_to_many :projects
  has_many :deals, :foreign_key => 'status_id', :dependent => :nullify
  has_many :deal_processes_from, :class_name => 'DealProcess',:foreign_key => 'old_value', :dependent => :delete_all
  has_many :deal_processes_to, :class_name => 'DealProcess', :foreign_key => 'value', :dependent => :delete_all
  acts_as_list :scope => 'status_type = #{status_type}'

  scope :open, where(:status_type => DealStatus::OPEN_STATUS)

  after_save     :update_default

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30

  def update_default
    DealStatus.update_all({:is_default => false}, ['id <> ?', id]) if self.is_default?
  end

  # Returns the default status for new Deals
  def self.default
    where(:is_default => true).first
  end

  # Returns an array of all statuses the given role can switch to
  # Uses association cache when called more than one time
  def new_statuses_allowed_to(roles, tracker)
    if roles && tracker
      role_ids = roles.collect(&:id)
      new_statuses = workflows.select {|w| role_ids.include?(w.role_id) && w.tracker_id == tracker.id}.collect{|w| w.new_status}.compact.sort
    else
      []
    end
  end

  # Same thing as above but uses a database query
  # More efficient than the previous method if called just once
  def find_new_statuses_allowed_to(roles, tracker)
    if roles && tracker
      workflows.find(:all,
      :include => :new_status,
      :conditions => { :role_id => roles.collect(&:id),
        :tracker_id => tracker.id}).collect{ |w| w.new_status }.compact.sort
    else
      []
    end
  end

  def is_open?
    self.status_type == OPEN_STATUS
  end

  def is_won?
    self.status_type == WON_STATUS
  end

  def is_lost?
    self.status_type == LOST_STATUS
  end

  def is_closed?
    !self.is_open?
  end

  def status_type_name
    case self.status_type
      when OPEN_STATUS then l(:label_open_issues)
      when WON_STATUS then l(:label_crm_deal_status_won)
      when LOST_STATUS then l(:label_crm_deal_status_lost)
      else ""
    end
  end

  def new_status_allowed_to?(status, roles, tracker)
    if status && roles && tracker
      !workflows.find(:first, :conditions => {:new_status_id => status.id, :role_id => roles.collect(&:id), :tracker_id => tracker.id}).nil?
    else
      false
    end
  end

  def color_name
    return "#" + "%06x" % self.color unless self.color.nil?
  end

  def color_name=(clr)
    self.color = clr.from(1).hex
  end


  def <=>(status)
    position <=> status.position
  end

  def to_s; name end

  private

  def check_integrity
    raise "Can't delete status" if Deal.where(:status_id => self.id).any?
  end

  # Deletes associated workflows
  def delete_workflows
    Workflow.delete_all(["old_status_id = :id OR new_status_id = :id", {:id => id}])
  end
end
