require_dependency 'project'

module ExtendedProjectPatch

    def self.included(base)
        base.extend(ClassMethods)
        unless base.method_defined?(:archived?)
            base.send(:include, ArchivedMethods)
        end
    end

    module ClassMethods

        @@available_columns_cache = []

        @@available_columns = [
            ExtendedColumn.new(:project, :css_classes => 'name'),
            ExtendedColumn.new(:description),
            ExtendedColumn.new(:homepage),
            ExtendedColumn.new(:parent),
            ExtendedColumn.new(:is_public,  :align => :center),
            ExtendedColumn.new(:created_on, :align => :center),
            ExtendedColumn.new(:updated_on, :align => :center),
            ExtendedColumn.new(:active,     :align => :center),
            ExtendedColumn.new(:downloads,
                               :value => lambda { |project| Attachment.sum(:downloads,
                                                                           :conditions => [ "(container_type = 'Project' AND container_id = ?) OR (container_type = 'Version' AND container_id IN (?))", project.id, project.versions.collect{ |version| version.id } ]) },
                               :align => :center),
            ExtendedColumn.new(:latest_downloads,
                               :caption => :label_latest_downloads,
                               :value => lambda { |project| (version = project.versions.sort.reverse.select{ |version| version.closed? }.first) && version.attachments.inject(0) { |count, attachment| count += attachment.downloads } },
                               :align => :center),
            ExtendedColumn.new(:maximum_downloads,
                               :caption => :label_maximum_downloads,
                               :value => lambda { |project| Attachment.maximum(:downloads,
                                                                               :conditions => [ "(container_type = 'Project' AND container_id = ?) OR (container_type = 'Version' AND container_id IN (?))", project.id, project.versions.collect{ |version| version.id } ]) },
                               :align => :center),
            ExtendedColumn.new(:files,
                               :caption => :label_file_plural,
                               :value => lambda { |project| project.attachments.size + project.versions.inject(0) { |count, version| count += version.attachments.size } },
                               :align => :center),
            ExtendedColumn.new(:latest_files,
                               :caption => :label_latest_files,
                               :value => lambda { |project| (version = project.versions.sort.reverse.select{ |version| version.closed? }.first) && version.attachments.size },
                               :align => :center),
            ExtendedColumn.new(:latest_version,
                               :caption => :label_latest_version,
                               :value => lambda { |project| project.versions.sort.reverse.select{ |version| version.closed? }.first },
                               :align => :center),
            ExtendedColumn.new(:next_version,
                               :caption => :label_next_version,
                               :value => lambda { |project| project.versions.sort.select{ |version| !version.closed? }.first },
                               :align => :center),
            ExtendedColumn.new(:total_issues,
                               :caption => :label_total_issues,
                               :value => lambda { |project| project.issues.count },
                               :align => :center),
            ExtendedColumn.new(:total_open_issues,
                               :caption => :label_total_open_issues,
                               :value => lambda { |project| project.issues.open.count },
                               :align => :center),
            ExtendedColumn.new(:last_activity,
                               :caption => :label_last_activity,
                               :value => lambda { |project| (event = Redmine::Activity::Fetcher.new(User.current, :project => project).events(nil, nil, :limit => 1).first) && event.event_date },
                               :align => :center),
            ExtendedColumn.new(:repository,
                               :caption => :label_repository,
                               :value => lambda { |project| !!project.repository },
                               :align => :center),
            ExtendedColumn.new(:repositories,
                               :caption => :label_repository_plural,
                               :value => lambda { |project| project.respond_to?(:repositories) ? project.repositories.size : 1 },
                               :align => :center),
            ExtendedColumn.new(:repository_type,
                               :caption => :label_repository_type,
                               :value => lambda { |project| project.repository && (project.repository.type.is_a?(Class) ? project.repository.type.name.gsub(%r{^Repository::}, '') : project.repository.type) },
                               :align => :center),
            ExtendedColumn.new(:repository_files,
                               :caption => :label_repository_files,
                               :value => lambda { |project| project.repository && (project.respond_to?(:repositories) ?
                                                            project.repositories.inject(0) { |count, repository| Change.count(:path, :distinct => true, :include => [ :changeset ], :conditions => [ "repository_id = ?", repository.id ]) } :
                                                            Change.count(:path, :distinct => true, :include => [ :changeset ], :conditions => [ "repository_id = ?", project.repository.id ])) },
                               :align => :center),
            ExtendedColumn.new(:forums,
                               :caption => :label_board_plural,
                               :value => lambda { |project| project.boards.size },
                               :align => :center),
            ExtendedColumn.new(:forum_messages,
                               :caption => :label_forum_messages,
                               :value => lambda { |project| project.boards.inject(0) { |count, board| count += board.messages.size } },
                               :align => :center)
        ]

        def available_columns
            if @@available_columns_cache.any?
                @@available_columns_cache
            else
                @@available_columns_cache = @@available_columns.dup

                Tracker.all.each do |tracker|
                    @@available_columns_cache << ExtendedTrackerColumn.new(tracker)
                    @@available_columns_cache << ExtendedTrackerColumn.new(tracker, :open => true)
                end
                IssueStatus.all.each do |status|
                    @@available_columns_cache << ExtendedIssueStatusColumn.new(status)
                end
                IssuePriority.all.each do |priority|
                    @@available_columns_cache << ExtendedPriorityColumn.new(priority)
                    @@available_columns_cache << ExtendedPriorityColumn.new(priority, :open => true)
                end
                Redmine::AccessControl.available_project_modules.each do |project_module|
                    @@available_columns_cache << ExtendedModuleColumn.new(project_module)
                end

                @@available_columns_cache += ProjectCustomField.all.collect{ |column| ExtendedCustomFieldColumn.new(column) }
            end
        end

        def add_available_column(column)
            @@available_columns << column if column.is_a?(ExtendedColumn)
            remove_class_variable(:@@available_columns_cache) if class_variable_defined?(:@@available_columns_cache)
        end

        def default_columns
            @@available_columns.select do |column|
                case column.name
                when :project, :is_public, :created_on
                    true
                else
                    false
                end
            end
        end

    end

    module ArchivedMethods

        def archived?
            self.status == self.class::STATUS_ARCHIVED
        end

    end
end
