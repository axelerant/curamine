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

class ContactsDrop < Liquid::Drop

  def initialize(contacts)
    @contacts = contacts
  end

  def before_method(id)
    contact = @contacts.where(:id => id).first || Contact.new
    ContactDrop.new contact
  end

  def all
    @all ||= @contacts.map do |contact|
      ContactDrop.new contact
    end
  end

  def visible
    @visible ||= @contacts.visible.map do |contact|
      ContactDrop.new contact
    end
  end

  def each(&block)
    all.each(&block)
  end

end


class ContactDrop < Liquid::Drop

  delegate :id, :name, :first_name, :last_name, :middle_name, :company, :phones, :emails, :primary_email, :website, :skype_name, :birthday, :age, :background, :job_title, :is_company, :tag_list, :post_address, :to => :@contact

  def initialize(contact)
    @contact = contact
  end

  def contact_company
    ContactDrop.new @contact.contact_company if @contact.contact_company
  end

  def company_contacts
    @contact.company_contacts.map{|c| ContactDrop.new c } if @contact.company_contacts
  end

  def avatar_diskfile
    @contact.avatar.diskfile
  end

  def avatar_url
    helpers.url_for :controller => "attachments", :action => "contacts_thumbnail", :id => @contact.avatar, :size => '64', :only_path => true
  end

  def notes
    @contact.notes.map{|n| NotesDrop.new(n) }
  end

  def address
    AddressDrop.new(@contact.address) if @contact.address
  end
  def custom_field_values
    @contact.custom_field_values
  end

  private

  def helpers
    Rails.application.routes.url_helpers
  end

end
