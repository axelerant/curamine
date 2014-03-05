require_dependency 'calendars_controller'

module ExtendedCalendarsControllerPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method :show, :extended_show
        end
    end

    module InstanceMethods

        def extended_show
            if params[:year] && params[:year].to_i > 1900
                @year  = params[:year].to_i
                @month = params[:month].to_i if params[:month] && params[:month].to_i > 0 && params[:month].to_i < 13
            end
            @year  ||= Date.today.year
            @month ||= Date.today.month

            @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
            retrieve_query
            @query.group_by = nil
            if @query.valid?
                events = []
                events += @query.issues(:include => [ :tracker, :assigned_to, :priority ],
                                        :conditions => [ "((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt ])
                events += @query.versions(:conditions => [ "effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt ])

                issue_ids = @query.respond_to?(:issue_ids) ? @query.issue_ids : @query.issues.collect(&:id)
                events += CustomValue.find(:all, :include => :custom_field,
                                                 :conditions => [ "#{CustomField.table_name}.field_format = ? AND #{CustomValue.table_name}.customized_type = ? AND #{CustomValue.table_name}.customized_id IN (?) AND STR_TO_DATE(#{CustomValue.table_name}.value, '%Y-%m-%d') BETWEEN ? AND ?",
                                                                  'date', 'Issue', issue_ids, @calendar.startdt, @calendar.enddt ])

                project_ids = @project ? [ @project.id ] : Project.visible.all.collect(&:id)
                events += CustomValue.find(:all, :include => :custom_field,
                                                 :conditions => [ "#{CustomField.table_name}.field_format = ? AND #{CustomValue.table_name}.customized_type = ? AND #{CustomValue.table_name}.customized_id IN (?) AND STR_TO_DATE(#{CustomValue.table_name}.value, '%Y-%m-%d') BETWEEN ? AND ?",
                                                                  'date', 'Project', project_ids, @calendar.startdt, @calendar.enddt ])

                version_ids = @project ? @project.versions.collect(&:id) : Version.visible.all.collect(&:id)
                events += CustomValue.find(:all, :include => :custom_field,
                                                 :conditions => [ "#{CustomField.table_name}.field_format = ? AND #{CustomValue.table_name}.customized_type = ? AND #{CustomValue.table_name}.customized_id IN (?) AND STR_TO_DATE(#{CustomValue.table_name}.value, '%Y-%m-%d') BETWEEN ? AND ?",
                                                                  'date', 'Version', version_ids, @calendar.startdt, @calendar.enddt ])

                @calendar.events = events
            end

            render :action => 'show', :layout => false if request.xhr?
        end

    end

end
