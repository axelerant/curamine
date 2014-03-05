require_dependency 'custom_field'

module ExtendedCustomFieldPatch

    def self.included(base)
        base.send(:include, AliasCastValueMethod)
        if base.method_defined?(:possible_values_options)
            base.send(:include, AliasPossibleValuesOptionsMethod)
            base.class_eval do
                unloadable

                alias_method_chain :possible_values_options, :extended
                alias_method_chain :cast_value,              :extended
            end
        else
            base.send(:include, OverridePossibleValuesMethod)
            base.class_eval do
                unloadable

                alias_method_chain :cast_value, :extended
            end
        end
    end

    module AliasPossibleValuesOptionsMethod

        def possible_values_options_with_extended(obj = nil)
            case field_format
            when 'project'
                if obj.is_a?(User)
                    projects = Project.visible(obj).all
                else
                    projects = Project.visible.all
                end
                projects.collect{ |project| [ project.name, project.id.to_s ] }
            else
                possible_values_options_without_extended(obj)
            end
        end

    end

    module OverridePossibleValuesMethod

        def possible_values(dummy = nil)
            case field_format
            when 'project'
                Project.visible.all.collect{ |project| [ project.name, project.id.to_s ] }
            else
                read_attribute(:possible_values)
            end
        end

        alias_method :possible_values_options, :possible_values

    end

    module AliasCastValueMethod

        def cast_value_with_extended(value)
            case field_format
            when 'wiki', 'link'
                value.blank? ? nil : value
            when 'project'
                unless value.blank?
                    Project.find_by_id(value)
                else
                    nil
                end
            else
                cast_value_without_extended(value)
            end
        end

    end

end
