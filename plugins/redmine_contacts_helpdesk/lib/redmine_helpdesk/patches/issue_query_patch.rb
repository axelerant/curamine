require_dependency 'query'

module RedmineHelpdesk
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, HelpdeskHelper)

        base.class_eval do
          unloadable

          base.add_available_column(QueryColumn.new(:last_message, :caption => :label_helpdesk_last_message))
          base.add_available_column(QueryColumn.new(:last_message_date, :caption => :label_helpdesk_last_message_date))
          base.add_available_column(QueryColumn.new(:customer, :caption => :label_helpdesk_customer))
          base.add_available_column(QueryColumn.new(:ticket_source, :caption => :label_helpdesk_ticket_source))
          base.add_available_column(QueryColumn.new(:customer_company, :caption => :label_helpdesk_customer_company))
          base.add_available_column(QueryColumn.new(:helpdesk_ticket, :caption => :label_helpdesk_ticket))

          alias_method_chain :available_filters, :helpdesk
          # alias_method_chain :issues, :helpdesk

        end
      end


      module InstanceMethods
        # def issues_with_helpdesk(options={})
        #   if project.blank? || (project && User.current.allowed_to?(:view_helpdesk_tickets, project))
        #     options[:include] = (options[:include] || []) + [:helpdesk_ticket]
        #   end
        #   issues_without_helpdesk(options)
        # end

        def sql_for_customer_field(field, operator, value)
          case operator
          when "*", "!*" # Member / Not member
            sw = operator == "!*" ? 'NOT' : ''
            "(#{Issue.table_name}.id #{sw} IN (SELECT DISTINCT #{HelpdeskTicket.table_name}.issue_id FROM #{HelpdeskTicket.table_name}))"
          when "=", "!"
            sw = operator == "!" ? 'NOT' : ''
            contacts_select = "SELECT #{HelpdeskTicket.table_name}.issue_id FROM #{HelpdeskTicket.table_name}
                                WHERE #{HelpdeskTicket.table_name}.contact_id IN (#{value.join(',')})"

            "(#{Issue.table_name}.id #{sw} IN (#{contacts_select}))"
          end
        end

        def sql_for_ticket_source_field(field, operator, value)
          case operator
          when "=", "!"
            sw = operator == "!" ? 'NOT' : ''
            contacts_select = "SELECT #{HelpdeskTicket.table_name}.issue_id FROM #{HelpdeskTicket.table_name}
                                WHERE #{HelpdeskTicket.table_name}.source IN (#{value.join(',')})"

            "(#{Issue.table_name}.id #{sw} IN (#{contacts_select}))"
          end
        end

        def sql_for_customer_company_field(field, operator, value)
          sw = ["!", "!~"].include?(operator) ? 'NOT' : ''
          case operator
          when "="
            like_value = "LIKE '#{value.first.to_s}'"
          when "!*"
            like_value = "IS NULL OR #{Contact.table_name}.company = ''"
          when "*"
            like_value = "IS NOT NULL OR #{Contact.table_name}.company <> ''"
          when "~", "!~"
            like_value ="LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
          end

          contacts_select = "SELECT #{HelpdeskTicket.table_name}.issue_id FROM #{HelpdeskTicket.table_name}
                              WHERE #{HelpdeskTicket.table_name}.contact_id IN (
                                SELECT #{Contact.table_name}.id
                                FROM #{Contact.table_name}
                                WHERE LOWER(#{Contact.table_name}.company) #{like_value}
                                )"

          "(#{Issue.table_name}.id #{sw} IN (#{contacts_select}))"
        end

        def available_filters_with_helpdesk
          # && !RedmineHelpdesk.settings[:issues_filters]
          if @available_filters.blank? && (project.blank? || (User.current.allowed_to?(:view_helpdesk_tickets, project) && User.current.allowed_to?(:view_contacts, project)))
            available_filters_without_helpdesk.merge!({ 'customer' => {
                :type => :list_optional,
                :name => l(:label_helpdesk_customer),
                :order  => 6,
                :values => contacts_for_select(project, :limit => 500) }}) if !available_filters_without_helpdesk.key?("customer")

            available_filters_without_helpdesk.merge!({ 'ticket_source' => {
                :type => :list,
                :name => l(:label_helpdesk_ticket_source),
                :order  => 7,
                :values => helpdesk_tickets_source_for_select }}) if !available_filters_without_helpdesk.key?("ticket_source")

            available_filters_without_helpdesk.merge!({ 'customer_company' => {
                :type => :string,
                :name => l(:label_helpdesk_customer_company),
                :order  => 8 }}) if !available_filters_without_helpdesk.key?("customer_company")

          else
            available_filters_without_helpdesk
          end
          @available_filters
        end
      end

    end
  end
end

if Redmine::VERSION.to_s > "2.3.0"
  unless IssueQuery.included_modules.include?(RedmineHelpdesk::Patches::IssueQueryPatch)
    IssueQuery.send(:include, RedmineHelpdesk::Patches::IssueQueryPatch)
  end
else
  unless Query.included_modules.include?(RedmineHelpdesk::Patches::IssueQueryPatch)
    Query.send(:include, RedmineHelpdesk::Patches::IssueQueryPatch)
  end
end


