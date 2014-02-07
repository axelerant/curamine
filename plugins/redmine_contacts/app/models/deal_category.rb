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

class DealCategory < ActiveRecord::Base
  unloadable
  belongs_to :project
  has_many :deals, :foreign_key => 'category_id', :dependent => :nullify
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 30

  alias :destroy_without_reassign :destroy

  # Destroy the category
  # If a category is specified, issues are reassigned to this category
  def destroy(reassign_to = nil)
    if reassign_to && reassign_to.is_a?(DealCategory) && reassign_to.project == self.project
      Deal.update_all("category_id = #{reassign_to.id}", "category_id = #{id}")
    end
    destroy_without_reassign
  end

  def <=>(category)
    name <=> category.name
  end

  def to_s; name end
end
