require 'redmine'

require_dependency 'extended_profile_hook'

Rails.logger.info 'Starting Extended Profile plugin for Redmine'

Rails.configuration.to_prepare do
    unless WikiController.included_modules.include?(CustomFieldsHelper)
        WikiController.send(:helper, :custom_fields)
        WikiController.send(:include, CustomFieldsHelper)
    end
end

Redmine::Plugin.register :extended_profile do
    name 'Extended profile'
    author 'Andriy Lesyuk'
    author_url 'http://www.andriylesyuk.com'
    description 'Adds many new fields to user profile.'
    url 'http://projects.andriylesyuk.com/projects/extended-profile'
    version '1.2.0'
end
