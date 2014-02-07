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

require "redmine_contacts/liquid/drops/contacts_drop"
require "redmine_contacts/liquid/drops/deals_drop"
require "redmine_contacts/liquid/drops/notes_drop"
require "redmine_contacts/liquid/drops/addresses_drop"

module RedmineContacts
  module Liquid
    module Filters
      include ContactsMoneyHelper

      def underscore(input)
        input.to_s.gsub(' ', '_').gsub('/', '_').underscore
      end

      def dasherize(input)
        input.to_s.gsub(' ', '-').gsub('/', '-').dasherize
      end

      def encode(input)
        Rack::Utils.escape(input)
      end

      # alias newline_to_br
      def multi_line(input)
        input.to_s.gsub("\n", '<br/>')
      end

      def concat(input, *args)
        result = input.to_s
        args.flatten.each { |a| result << a.to_s }
        result
      end

      # right justify and padd a string
      def rjust(input, integer, padstr = '')
        input.to_s.rjust(integer, padstr)
      end

      # left justify and padd a string
      def ljust(input, integer, padstr = '')
        input.to_s.ljust(integer, padstr)
      end

      def textile(input)
        ::RedCloth3.new(input).to_html
      end

      def currency(input, currency_code=nil)
        price_to_currency(input, currency_code || container_currency, :converted => false)
      end

      def custom_field(input, field_name)
        if input.respond_to?(:custom_field_values)
          input.custom_field_values.detect{|cfv| cfv.custom_field.name == field_name}.try(:value)
        end
      end

      def attachment(input, file_name)
        if input.respond_to?(:attachments)
          input.attachments.detect{|a| a.file_name == file_name}.try(:diskfile)
        end
      end

    private
      def container
        @container ||= @context.registers[:container]
      end

      def container_currency
        container.currency if container.respond_to?(:currency)
      end

    end

    ::Liquid::Template.register_filter(RedmineContacts::Liquid::Filters)

  end
end
