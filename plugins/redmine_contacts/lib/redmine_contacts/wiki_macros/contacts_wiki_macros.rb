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

module RedmineContacts
  module WikiMacros
    Redmine::WikiFormatting::Macros.register do

      desc "Contact Description Macro"
      macro :contact_plain do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
          first_name, last_name = args.first.split
          conditions = {:first_name => first_name}
          conditions[:last_name] = last_name if last_name
          contact = Contact.visible.find(:first, :conditions => conditions)
        else
          contact = Contact.visible.find_by_id(args.first)
        end
        link_to_source(contact) if contact
      end

      desc "Contact avatar"
      macro :contact_avatar do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
          first_name, last_name = args.first.split
          conditions = {:first_name => first_name}
          conditions[:last_name] = last_name if last_name
          contact = Contact.visible.find(:first, :conditions => conditions)
        else
          contact = Contact.visible.find_by_id(args.first)
        end
        link_to avatar_to(contact, :size => "32"),  contact_path(contact), :id => "avatar", :title => contact.name if contact
      end

      desc "Contact with avatar"
      macro :contact do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
          first_name, last_name = args.first.split
          conditions = {:first_name => first_name}
          conditions[:last_name] = last_name if last_name
          contact = Contact.visible.find(:first, :conditions => conditions)
        else
          contact = Contact.visible.find_by_id(args.first)
        end
        contact_tag(contact) if contact
      end

      desc "Contact/Deal note"
      macro :contact_note do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        note = Note.find_by_id(args.first)
        textilizable(note, :content).html_safe if note && note.source.visible?
      end

      desc "Deal"
      macro :deal do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        deal = Deal.visible.find(args.first)
        s = ''
        s << avatar_to(deal, :size => "16") + " "
        s << link_to(deal.full_name, polymorphic_url(deal)) + " "
        s << content_tag('span',
                         deal.status,
                         :style => "background-color:#{deal.status.color_name};color:white;padding: 3px 4px;font-size: 10px;white-space: nowrap;margin-right: 4px;", :class => "tag-label-color") if deal.status
        s.html_safe
      end


    end

  end
end
