require_dependency 'custom_field'

module ExtendedCustomFieldPatch

    def self.included(base)
        if base.method_defined?(:possible_values_options)
            base.send(:include, AliasPossibleValuesOptionsMethod)
            base.class_eval do
                unloadable

                alias_method_chain :possible_values_options, :extended
            end
        else
            base.send(:include, OverridePossibleValuesMethod)
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

end
