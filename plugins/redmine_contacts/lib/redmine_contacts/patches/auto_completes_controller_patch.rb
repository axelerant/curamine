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

require_dependency 'auto_completes_controller'

module RedmineContacts
  module Patches
    module AutoCompletesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          helper :contacts
        end
      end

      module InstanceMethods
        def contact_tags
          @name = params[:q].to_s
          @tags = Contact.available_tags :name_like => @name, :limit => 10
          render :layout => false, :partial => 'crm_tag_list'
        end

        def taggable_tags
          klass = Object.const_get(params[:taggable_type].camelcase)
          @name = params[:q].to_s
          @tags = klass.all_tag_counts(:conditions => ["#{ActsAsTaggableOn::Tag.table_name}.name LIKE ?", "%#{@name}%"], :limit => 10)
          render :layout => false, :partial => 'crm_tag_list'
        end

        def contacts
          @contacts = []
          q = (params[:q] || params[:term]).to_s.strip
            scope = Contact.scoped({})
            scope = scope.includes(:avatar)
            scope = scope.scoped.limit(params[:limit] || 10)
            scope = scope.scoped.companies if params[:is_company]
            scope = scope.joins(:projects).uniq.where(Contact.visible_condition(User.current))
            scope = scope.live_search(q) unless q.blank?
            scope = scope.by_project(@project) if @project
            @contacts = scope.sort!{|x, y| x.name <=> y.name }

          render :layout => false, :partial => 'contacts'
        end

        def companies
          @companies = []
          q = (params[:q] || params[:term]).to_s.strip
          if q.present?
            scope = Contact.scoped({})
            scope = scope.includes(:avatar)
            scope = scope.scoped.limit(params[:limit] || 10)
            scope = scope.by_project(@project) if @project
            @companies = scope.visible.companies.like_by(:first_name, q).sort!{|x, y| x.name <=> y.name }
          end
          render :layout => false, :partial => 'companies'
        end

      end
    end
  end
end

unless AutoCompletesController.included_modules.include?(RedmineContacts::Patches::AutoCompletesControllerPatch)
  AutoCompletesController.send(:include, RedmineContacts::Patches::AutoCompletesControllerPatch)
end
