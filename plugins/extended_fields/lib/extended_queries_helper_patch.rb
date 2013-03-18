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
            value = column.value(issue)

            case value.class.name
            when 'CustomValue'
                h(show_value(value))
            else
                column_content_without_extended(column, issue)
            end
        end

    end

end
