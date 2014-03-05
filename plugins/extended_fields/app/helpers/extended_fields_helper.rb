module ExtendedFieldsHelper

    def find_custom_field_template(custom_field)
        filename = custom_field.name.gsub(%r{[^a-z0-9_]+}i, '_').downcase
        filename.gsub!(%r{(^_+|_+$)}, '')

        format_extension = ''
        # Redmine 2.x.x
        if respond_to?(:formats)
            format_extension = ".#{formats.first}"
        # Redmine 1.x.x
        elsif request && request.respond_to?(:template_format)
            format_extension = ".#{request.template_format}"
        # Mailer
        elsif controller
            # Redmine 1.x.x
            if controller.respond_to?(:template)
                format_extension = ".#{controller.template.template_format}"
            # Redmine 2.x.x
            elsif controller.respond_to?(:lookup_context)
                format_extension = ".#{controller.lookup_context.formats.first}"
            end
        end

        unless filename.empty?
            self.view_paths.each do |load_path|
                if template = load_path["custom_values/#{custom_field.field_format}/_#{filename}#{format_extension}"]
                    return "custom_values/#{custom_field.field_format}/#{filename}"
                end
            end
        end

        self.view_paths.each do |load_path|
            if template = load_path["custom_values/common/_#{custom_field.field_format}#{format_extension}"]
                return "custom_values/common/#{custom_field.field_format}"
            end
        end

        nil
    end

    def find_custom_field_edit_template(custom_field)
        filename = custom_field.name.gsub(%r{[^a-z0-9_]+}i, '_').downcase
        filename.gsub!(%r{(^_+|_+$)}, '')

        unless filename.empty?
            self.view_paths.each do |load_path|
                if template = load_path["custom_edits/#{custom_field.field_format}/_#{filename}.html"]
                    return "custom_edits/#{custom_field.field_format}/#{filename}"
                end
            end
        end

        self.view_paths.each do |load_path|
            if template = load_path["custom_edits/common/_#{custom_field.field_format}.html"]
                return "custom_edits/common/#{custom_field.field_format}"
            end
        end

        nil
    end

    def custom_value_for_user(name, user = User.current)
        custom_field = CustomField.find_by_name_and_type(name, 'UserCustomField')
        if custom_field
            custom_value = user.custom_value_for(custom_field)
            if custom_value && !custom_value.value.blank?
                custom_value
            else
                nil
            end
        else
            nil
        end
    end

    def extended_column_content(column, object)
        value = column.value(object)

        case object
        when User
            case column.name
            when :login
                return (avatar(object, :size => 14) || '').html_safe + link_to(h(value), :action => 'edit', :id => object)
            when :mail
                return mail_to(h(value))
            when :status
                return h(l("status_" + %w(anonymous active registered locked)[value]))
            when :language
                language = valid_languages.detect{ |lang| lang.to_s == value }
                return h(ll(language.to_s, :general_lang_name))
            end
        when Project
            case column.name
            when :project
                return content_tag(:span, link_to_project(object, { :action => 'settings' }, :title => object.short_description))
            when :description
                return textilizable(object.short_description, :project => object)
            when :created_on
                return format_date(value)
            when :homepage
                return link_to(h(value), value)
            when :active
                return checked_image(object.status == 1)
            end
        end

        case value
        when CustomValue
            return show_value(value)
        when User
            return link_to_user(value)
        when Project
            return link_to_project(value)
        when Version
            return link_to(h(value), :controller => 'versions', :action => 'show', :id => value)
        when Issue
            return link_to_issue(value, :subject => false)
        when Time
            return format_time(value)
        when Date
            return format_date(value)
        when TrueClass
            return checked_image(value)
        when FalseClass
            return nil
        else
            return h(value)
        end
    end

end
