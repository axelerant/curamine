class ExtendedColumn
    include Redmine::I18n

    attr_accessor :name, :align

    def initialize(name, options = {})
        self.name = name
        self.align = options[:align] if options[:align]

        @caption = options[:caption] || "field_#{name}".to_sym
        @value = options[:value] if options[:value]
        @css_classes = options[:css_classes] if options[:css_classes]
    end

    def css_classes
        @css_classes || name
    end

    def caption
        l(@caption)
    end

    def value(object)
        if @value
            if @value.is_a?(Proc)
                @value.call(object)
            else
                object.send(@value)
            end
        elsif object.respond_to?(name)
            object.send(name)
        end
    end

end
