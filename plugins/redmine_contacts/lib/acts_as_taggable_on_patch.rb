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

require 'acts-as-taggable-on'

module ActsAsTaggableOn::Taggable
  module Core
    module InstanceMethods
      def tag_list_cache_on(context)
        variable_name = "@#{context.to_s.singularize}_list"
        if instance_variable_get(variable_name)
          instance_variable_get(variable_name)
        elsif self.class.respond_to?(:caching_tag_list_on?) && self.class.caching_tag_list_on?(context) && cached_tag_list_on(context)
          instance_variable_set(variable_name, ActsAsTaggableOn::TagList.from(cached_tag_list_on(context)))
        else
          instance_variable_set(variable_name, ActsAsTaggableOn::TagList.new(tags_on(context).map(&:name)))
        end
      end
    end
  end
end
