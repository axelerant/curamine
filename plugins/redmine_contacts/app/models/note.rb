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

class Note < ActiveRecord::Base
  unloadable

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :source, :polymorphic => true, :touch => true

  # added as a quick fix to allow eager loading of the polymorphic association for multiprojects

  validates_presence_of :source, :author, :content

  acts_as_customizable
  acts_as_attachable :view_permission => :view_contacts,
                     :delete_permission => :edit_contacts

  acts_as_event :title => Proc.new {|o| "#{l(:label_crm_note_for)}: #{o.source.name}"},
                :type => "issue-note",
                :group => :source,
                :url => Proc.new {|o| {:controller => 'notes', :action => 'show', :id => o.id }},
                :description => Proc.new {|o| o.content}

  cattr_accessor :note_types
  @@note_types = {:email => 0, :call => 1, :meeting => 2}
  cattr_accessor :cut_length
  @@cut_length = 1000

  def self.note_types
    @@note_types
  end

  def note_time
    self.created_on.to_s(:time) unless self.created_on.blank?
  end

  def note_time=(val)
    if !self.created_on.blank? && val.to_s.gsub(/\s/, "").match(/^(\d{1,2}):(\d{1,2})$/)
      self.created_on = self.created_on.change({:hour => $1.to_i % 24, :min => $2.to_i % 60})
    end
  end

  def self.available_authors(prj=nil)
    options = {}
    options[:select] = "DISTINCT #{User.table_name}.*"
    options[:joins] = "JOIN #{Note.table_name} nnnn ON nnnn.author_id = #{User.table_name}.id"
    options[:order] = "#{User.table_name}.lastname, #{User.table_name}.firstname"
    prj.nil? ? User.active.find(:all, options) : prj.users.active.find(:all, options)
  end

  def project
     self.source.respond_to?(:project) ? self.source.project : nil
  end

  def editable_by?(usr, prj=nil)
    prj ||= @project || self.project
    usr && (usr.allowed_to?(:delete_notes, prj) || (self.author == usr && usr.allowed_to?(:delete_own_notes, prj)))
    # usr && usr.logged? && (usr.allowed_to?(:edit_notes, project) || (self.author == usr && usr.allowed_to?(:edit_own_notes, project)))
  end

  def destroyable_by?(usr, prj=nil)
    prj ||= @project || self.project
    usr && (usr.allowed_to?(:delete_notes, prj) || (self.author == usr && usr.allowed_to?(:delete_own_notes, prj)))
  end

  def created_on
    return nil if super.blank?
    zone = User.current.time_zone
    zone ? super.in_time_zone(zone) : (super.utc? ? super.localtime : super)
  end

end
