require 'redmine'

require_dependency 'extended_fields_hook'

Rails.logger.info 'Starting Extended Fields plugin for Redmine'

Redmine::CustomFieldFormat.map do |fields|
    if Redmine::VERSION::MAJOR < 2 || defined?(ChiliProject)
        base_order = 2
    else
        base_order = 1
    end

    fields.register    WikiCustomFieldFormat.new('wiki',    :label => :label_wiki_text, :order => base_order + 0.1)
    fields.register    LinkCustomFieldFormat.new('link',    :label => :label_link,      :order => base_order + 0.2)
    fields.register ProjectCustomFieldFormat.new('project', :label => :label_project,   :order => base_order + 6)
end

issue_query = (IssueQuery rescue Query)

issue_query.add_available_column(ExtendedQueryColumn.new(:notes,
                                                         :value => lambda { |issue| issue.journals.select{ |journal| journal.notes.present? }.size }))

issue_query.add_available_column(ExtendedQueryColumn.new(:changes,
                                                         :caption => :label_change_plural,
                                                         :value => lambda { |issue| issue.journals.select{ |journal| journal.details.any? }.size }))

issue_query.add_available_column(ExtendedQueryColumn.new(:watchers,
                                                         :caption => :label_issue_watchers,
                                                         :value => lambda { |issue| issue.watchers.size }))

Rails.configuration.to_prepare do

    unless String.method_defined?(:html_safe)
        String.send(:include, ExtendedStringHTMLSafePatch)
    end

    unless ActionView::Base.included_modules.include?(ExtendedFieldsHelper)
        ActionView::Base.send(:include, ExtendedFieldsHelper)
    end

    unless defined? ActiveSupport::SafeBuffer
        unless ActionView::Base.included_modules.include?(ExtendedHTMLEscapePatch)
            ActionView::Base.send(:include, ExtendedHTMLEscapePatch)
        end
    end

    unless AdminController.included_modules.include?(ExtendedAdminControllerPatch)
        AdminController.send(:include, ExtendedAdminControllerPatch)
    end
    unless UsersController.included_modules.include?(ExtendedUsersControllerPatch)
        UsersController.send(:include, ExtendedUsersControllerPatch)
    end
    unless IssuesController.included_modules.include?(ExtendedIssuesControllerPatch)
        IssuesController.send(:include, ExtendedIssuesControllerPatch)
    end
    unless CalendarsController.included_modules.include?(ExtendedCalendarsControllerPatch)
        CalendarsController.send(:include, ExtendedCalendarsControllerPatch)
    end
    unless CustomFieldsHelper.included_modules.include?(ExtendedFieldsHelperPatch)
        CustomFieldsHelper.send(:include, ExtendedFieldsHelperPatch)
    end
    unless QueriesHelper.included_modules.include?(ExtendedQueriesHelperPatch)
        QueriesHelper.send(:include, ExtendedQueriesHelperPatch)
    end
    unless CustomField.included_modules.include?(ExtendedCustomFieldPatch)
        CustomField.send(:include, ExtendedCustomFieldPatch)
    end
    begin
        unless CustomFieldValue.included_modules.include?(ExtendedCustomFieldValuePatch)
            CustomFieldValue.send(:include, ExtendedCustomFieldValuePatch)
        end
    rescue NameError
    end
    unless CustomValue.included_modules.include?(ExtendedCustomValuePatch)
        CustomValue.send(:include, ExtendedCustomValuePatch)
    end
    unless Query.included_modules.include?(ExtendedCustomQueryPatch)
        Query.send(:include, ExtendedCustomQueryPatch)
    end
    unless Project.included_modules.include?(ExtendedProjectPatch)
        Project.send(:include, ExtendedProjectPatch)
    end
    unless User.included_modules.include?(ExtendedUserPatch)
        User.send(:include, ExtendedUserPatch)
    end

    unless AdminController.included_modules.include?(CustomFieldsHelper)
        AdminController.send(:helper, :custom_fields)
        AdminController.send(:include, CustomFieldsHelper)
    end
    unless WikiController.included_modules.include?(CustomFieldsHelper)
        WikiController.send(:helper, :custom_fields)
        WikiController.send(:include, CustomFieldsHelper)
    end

    if defined? ActionView::OptimizedFileSystemResolver
        unless ActionView::OptimizedFileSystemResolver.method_defined?(:[])
            ActionView::OptimizedFileSystemResolver.send(:include, ExtendedFileSystemResolverPatch)
        end
    end

    if CustomField.method_defined?(:format_in?)
        unless CustomField.included_modules.include?(ExtendedFormatInPatch)
            CustomField.send(:include, ExtendedFormatInPatch)
        end
    end

    if defined? XlsExportController
        unless XlsExportController.included_modules.include?(ExtendedFieldsHelper)
            XlsExportController.send(:include, ExtendedFieldsHelper)
        end
    end
end

Redmine::Plugin.register :extended_fields do
    name 'Extended fields'
    author 'Andriy Lesyuk'
    author_url 'http://www.andriylesyuk.com'
    description 'Adds new custom field types, improves listings etc.'
    url 'http://projects.andriylesyuk.com/projects/extended-fields'
    version '0.2.2'
end
