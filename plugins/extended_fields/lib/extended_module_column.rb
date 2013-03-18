class ExtendedModuleColumn < ExtendedColumn

    def initialize(project_module)
        self.name = "project_module_#{project_module}".to_sym
        self.align = :center

        @caption = :label_project_module
        @module = project_module
    end

    def caption
        l(:label_project_module, :module => l_or_humanize(@module, :prefix => 'project_module_'))
    end

    def value(project)
        !!project.module_enabled?(@module)
    end

end
