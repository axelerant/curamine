require_dependency 'query'

class ExtendedQueryColumn < QueryColumn

    def initialize(name, options = {})
        super
        @value = options[:value] if options[:value]
    end

    def value(issue)
        if @value
            if @value.is_a?(Proc)
                @value.call(issue)
            else
                issue.send(@value)
            end
        else
            issue.send(name)
        end
    end

end
