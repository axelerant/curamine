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

class Deal < ActiveRecord::Base
  unloadable

  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :category, :class_name => 'DealCategory', :foreign_key => 'category_id'
  belongs_to :contact
  belongs_to :status, :class_name => "DealStatus", :foreign_key => "status_id"
  has_many :deals, :class_name => "deal", :foreign_key => "reference_id"
  has_many :notes, :as => :source, :class_name => 'DealNote', :dependent => :delete_all, :order => "created_on DESC"
  has_many :deal_processes, :dependent => :delete_all
  has_and_belongs_to_many :related_contacts, :class_name => 'Contact', :order => "#{Contact.table_name}.last_name, #{Contact.table_name}.first_name", :uniq => true
  scope :visible, lambda {|*args| { :include => :project,
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_deals)} }
  scope :by_project, lambda {|project_id| where(:project_id => project_id) unless project_id.blank? }
  scope :deletable, lambda {|*args| { :include => :project,
                                            :conditions => Project.allowed_to_condition(args.first || User.current, :delete_deals) }}

  scope :live_search, lambda {|search| {:conditions =>   ["(#{Deal.table_name}.name LIKE ?)", "%#{search}%"] }}

  scope :open, :include => :status, :conditions => ["(#{DealStatus.table_name}.status_type = ? OR #{DealStatus.table_name}.status_type IS NULL)", DealStatus::OPEN_STATUS]
  scope :closed, joins(:status).where("#{DealStatus.table_name}.status_type <> #{DealStatus::OPEN_STATUS}")
  scope :won, :include => :status, :conditions => ["#{DealStatus.table_name}.status_type = ?", DealStatus::WON_STATUS]
  scope :lost, :include => :status, :conditions => ["#{DealStatus.table_name}.status_type = ?", DealStatus::LOST_STATUS]
  scope :was_in_status, lambda{|status_id| joins(:deal_processes).where(["#{DealProcess.table_name}.old_value = ? OR #{DealProcess.table_name}.value = ?", status_id, status_id]).uniq}

  acts_as_customizable
  acts_as_viewable
  acts_as_watchable
  acts_as_attachable :view_permission => :view_deals,
                     :delete_permission => :edit_deals

  acts_as_event :datetime => :created_on,
               :url => Proc.new {|o| {:controller => 'deals', :action => 'show', :id => o}},
               :type => 'icon-add-deal',
               :title => Proc.new {|o| o.name },
               :description => Proc.new {|o| [o.price_to_s, o.contact ? o.contact.name : nil, o.background].join(' ').strip }

  acts_as_activity_provider :type => 'deals',
                            :permission => :view_deals,
                            :author_key => :author_id,
                            :find_options => {:include => :project}

  acts_as_searchable :columns => ["#{table_name}.name",
                                  "#{table_name}.background"],
                      :include => [:project],
                      # sort by id so that limited eager loading doesn't break with postgresql
                      :order_column => "#{table_name}.id"



  validates_presence_of :name
  validates_numericality_of :price, :allow_nil => true

  after_update :create_deal_process

  include ActionView::Helpers::NumberHelper
  include ::DealsHelper

  safe_attributes 'name',
    'background',
    'currency',
    'price',
    'price_type',
    'duration',
    'project_id',
    'author_id',
    'assigned_to_id',
    'status_id',
    'contact_id',
    'category_id',
    'probability',
    'due_date',
    'custom_field_values',
    'custom_fields',
    'watcher_user_ids',
    :if => lambda {|deal, user| deal.new_record? || user.allowed_to?(:edit_deals, deal.project) }

  def initialize(attributes=nil, *args)
    super
    if new_record?
      # set default values for new records only
      self.status_id = DealStatus.default.try(:id)
      self.currency ||= ContactsSetting.default_currency
    end
  end

  def avatar

  end

  def expected_revenue
    self.probability ? (self.probability.to_f / 100) * self.price : self.price
  end

  def full_name
    result = ''
    result << self.contact.name + ": " unless self.contact.blank?
    result << self.name
  end

  def all_contacts
    @all_contacts ||= ([self.contact] + self.related_contacts ).uniq
  end

  def self.available_users(prj=nil)
    cond = "(1=1)"
    cond << " AND #{Deal.table_name}.project_id = #{prj.id}" if prj
    User.active.find(:all, :select => "DISTINCT #{User.table_name}.*", :joins => "JOIN #{Deal.table_name} ON #{Deal.table_name}.assigned_to_id = #{User.table_name}.id", :conditions => cond, :order => "#{User.table_name}.lastname, #{User.table_name}.firstname")
  end

  def open?
    self.status.blank? || self.status.is_open?
  end

  def init_deal_process(author)
    @current_deal_process ||= DealProcess.new(:deal => self, :author => (author || User.current))
    @deal_status_before_change = self.new_record? ? nil : self.status_id
    updated_on_will_change!
    @current_deal_process
  end

  def create_deal_process
    if @current_deal_process && @deal_status_before_change && !(@deal_status_before_change == self.status_id)
      @current_deal_process.old_value = @deal_status_before_change
      @current_deal_process.value = self.status_id
      @current_deal_process.save
      init_deal_process @current_deal_process.author
    end
  end

  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_deals, self.project)
  end

  def editable?(usr=nil)
    (usr || User.current).allowed_to?(:edit_deals, self.project)
  end

  def destroyable?(usr=nil)
    (usr || User.current).allowed_to?(:delete_deals, self.project)
  end

  # Returns an array of projects that user can move deal to
  def self.allowed_target_projects(user=User.current)
    Project.all(:conditions => Project.allowed_to_condition(user, :add_deals))
  end


  # Returns the mail adresses of users that should be notified
  def recipients
    notified = []
    # Author and assignee are always notified unless they have been
    # locked or don't want to be notified
    notified << author if author
    if assigned_to
      notified += (assigned_to.is_a?(Group) ? assigned_to.users : [assigned_to])
    end
    notified = notified.select {|u| u.active? && u.notify_about?(self)}

    notified += project.notified_users
    notified.uniq!
    # Remove users that can not view the contact
    notified.reject! {|user| !visible?(user)}
    notified.collect(&:mail)
  end

  def status_was
    if status_id_changed? && status_id_was.present?
      @status_was ||= DealStatus.find_by_id(status_id_was)
    end
  end

  def price_to_s
    object_price(self)
  end

  def copy_from(arg)
    deal = arg.is_a?(Deal) ? arg : Deal.visible.find(arg)
    self.attributes = deal.attributes.dup.except("id", "created_at", "updated_at")
    self.custom_field_values = deal.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
    self
  end

  def info
   result = ""
   result = self.status.name if self.status
   result = result + " - " + self.price_to_s unless self.price.blank?
   result.html_safe
  end
end
