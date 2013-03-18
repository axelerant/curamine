module ExtendedFileSystemResolverPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
    end

    module InstanceMethods

        def [](template)
            @custom_field_templates ||= {}

            if @custom_field_templates.has_key?(template)
                @custom_field_templates[template]
            elsif File.exist?(File.join(@path, "#{template}.erb"))
                @custom_field_templates[template] = true
            else
                @custom_field_templates[template] = false
            end
        end

    end

end
