require_dependency 'queries_helper'

module ExtendedQueriesHelperPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method_chain :column_content, :extended
        end
    end

    module InstanceMethods

        def column_content_with_extended(column, issue)
            if column.is_a?(QueryCustomFieldColumn)
                value = issue.custom_field_values.detect{ |value| value.custom_field_id == column.custom_field.id }

                h(show_value(value))
            else
                value = column.value(issue)

                if value.is_a?(CustomValue)
                    h(show_value(value))
                else
                    column_content_without_extended(column, issue)
                end
            end
        end

    end

end
