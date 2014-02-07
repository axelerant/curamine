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

class NotesDrop < Liquid::Drop

  def initialize(notes)
    @notes = notes
  end

  def before_method(id)
    note = @notes.where(:id => id).first || Note.new
    NoteDrop.new note
  end

  def all
    @all ||= @notes.map do |note|
      NoteDrop.new note
    end
  end

  def visible
    @visible ||= @notes.visible.map do |note|
      NoteDrop.new note
    end
  end

  def each(&block)
    all.each(&block)
  end

end


class NoteDrop < Liquid::Drop

  delegate :id, :subject, :content, :type_id, :to => :@note

  def initialize(note)
    @note = note
  end
  def custom_field_values
    @note.custom_field_values
  end

end
