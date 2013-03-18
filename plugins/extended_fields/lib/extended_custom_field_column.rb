class ExtendedCustomFieldColumn < ExtendedColumn

    def initialize(custom_field)
        self.name = "cf_#{custom_field.id}".to_sym

        @caption = custom_field.name
        @custom_field = custom_field
        @css_classes = "#{self.name} #{custom_field.field_format}"
    end

    def caption
        @caption
    end

    def value(object)
        object.custom_values.detect{ |value| value.custom_field_id == @custom_field.id }
    end

end
