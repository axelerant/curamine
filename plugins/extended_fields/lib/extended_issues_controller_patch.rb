require_dependency 'issues_controller'

module ExtendedIssuesControllerPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
    end

    module InstanceMethods

        # Overriding existing method
        def fetch_row_values(issue, query, level)
            query.columns.collect do |column|
                s = if column.is_a?(QueryCustomFieldColumn)
                    cv = issue.custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
                    show_value(cv)
                elsif column.is_a?(ExtendedQueryColumn)
                    column.value(issue)
                else
                    value = issue.send(column.name)
                    if column.name == :subject
                        value = "  " * level + value
                    end
                    if value.is_a?(Date)
                        format_date(value)
                    elsif value.is_a?(Time)
                        format_time(value)
                    else
                        value
                    end
                end
                s.to_s
            end
        end

    end

end
