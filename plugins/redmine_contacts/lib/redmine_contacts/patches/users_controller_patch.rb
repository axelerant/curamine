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

require_dependency 'users_controller'
require_dependency 'user'

module RedmineContacts
  module Patches
    module UsersControllerPatch

      def self.included(base) # :nodoc:
        base.class_eval do
          helper :contacts
        end
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        def new_from_contact
          contact = Contact.visible.find(params[:contact_id])
          @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
          @user.firstname = contact.first_name
          @user.lastname = contact.last_name
          @user.mail = contact.emails.first
          @auth_sources = AuthSource.find(:all)
          respond_to do |format|
            format.html { render :action => 'new' }
          end
        end

      end
    end
  end
end

unless UsersController.included_modules.include?(RedmineContacts::Patches::UsersControllerPatch)
  UsersController.send(:include, RedmineContacts::Patches::UsersControllerPatch)
end
