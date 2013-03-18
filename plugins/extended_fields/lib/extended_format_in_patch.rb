require_dependency 'custom_field'

module ExtendedFormatInPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method_chain :format_in?, :extended
        end
    end

    module InstanceMethods

        def format_in_with_extended?(*args)
            case field_format
            when 'wiki'
                args.include?('text')
            when 'link'
                args.include?('string')
            when 'project'
                args.include?('version')
            else
                format_in_without_extended?(*args)
            end
        end

    end

end
