require_dependency 'query'

module ExtendedQueryCustomFieldColumn

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method :value, :extended_value
        end
    end

    module InstanceMethods

        def extended_value(issue)
            issue.custom_values.detect{ |value| value.custom_field_id == @cf.id }
        end

    end

end
