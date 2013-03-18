class WikiCustomFieldFormat < Redmine::CustomFieldFormat

    def format_as_wiki(value)
        return value
    end

    def edit_as
        'text'
    end

end
