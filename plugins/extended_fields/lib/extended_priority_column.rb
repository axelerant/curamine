class ExtendedPriorityColumn < ExtendedColumn

    def initialize(priority, options = {})
        @open = options[:open]

        if @open
            self.name = "open_priority_#{priority.position}_issues".to_sym
            @caption = :label_open_priority_column
        else
            self.name = "priority_#{priority.position}_issues".to_sym
            @caption = :label_priority_column
        end
        self.align = :center

        @css_classes = "priority-#{priority.position}"
        @priority = priority
    end

    def caption
        l(@caption, :priority => @priority.name)
    end

    def value(project)
        if @open
            Issue.open.count(:conditions => [ "project_id = ? AND priority_id = ?", project.id, @priority.id ])
        else
            Issue.count(:conditions => [ "project_id = ? AND priority_id = ?", project.id, @priority.id ])
        end
    end

end
