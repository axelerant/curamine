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

class ContactNote < Note
  unloadable
  belongs_to :contact, :foreign_key => :source_id

  acts_as_searchable :columns => ["#{table_name}.content"],
                     :include => [:contact => :projects],
                     :project_key => "#{Project.table_name}.id",
                     :permission => :view_contacts,
                     # sort by id so that limited eager loading doesn't break with postgresql
                     :order_column => "#{table_name}.id"

  acts_as_activity_provider :type => 'contacts',
                            :permission => :view_contacts,
                            :author_key => :author_id,
                            :find_options => {:include => [:contact => :projects], :conditions => {:source_type => 'Contact'} }

  scope :visible,
        lambda {|*args| { :include => [:contact => :projects],
                          :conditions => Contact.visible_condition(args.shift || User.current, *args) +
                                         " AND (#{ContactNote.table_name}.source_type = 'Contact')"}}

end
