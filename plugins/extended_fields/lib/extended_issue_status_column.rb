class ExtendedIssueStatusColumn < ExtendedColumn

    def initialize(status)
        self.name = "status_#{status.position}_issues".to_sym
        self.align = :center

        @caption = :label_issue_status_column
        @css_classes = "status-#{status.position}"
        @status = status
    end

    def caption
        l(@caption, :status => @status.name)
    end

    def value(project)
        Issue.count(:conditions => [ "project_id = ? AND status_id = ?", project.id, @status.id ])
    end

end
