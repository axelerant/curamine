class MigrateExtendedProfile < ActiveRecord::Migration

    def self.up
        pos = UserCustomField.maximum(:position) || 0
        settings = Setting.respond_to?(:plugin_extended_profile) ? Setting.plugin_extended_profile : nil

        company      = UserCustomField.create(:name => 'Company',             :field_format => 'string',  :position => pos += 1, :is_for_new => false, :searchable => true)
        company_site = UserCustomField.create(:name => 'Company website',     :field_format => 'link',    :position => pos += 1, :is_for_new => false)
        position     = UserCustomField.create(:name => 'Position',            :field_format => 'string',  :position => pos += 1, :is_for_new => false, :searchable => true)
        project      = UserCustomField.create(:name => 'Project of interest', :field_format => 'project', :position => pos += 1, :searchable => true,  :is_required => (settings && settings[:require_project]) ? true : false)
        website      = UserCustomField.create(:name => 'Personal website',    :field_format => 'link',    :position => pos += 1, :is_for_new => false)
        blog         = UserCustomField.create(:name => 'Blog',                :field_format => 'link',    :position => pos += 1, :is_for_new => false)
        facebook     = UserCustomField.create(:name => 'Facebook',            :field_format => 'string',  :position => pos += 1, :is_for_new => false, :regexp => '^([0-9]+|[A-Za-z0-9.]+)$', :hint => 'e.g. 100000066953233 or andriy.lesyuk')
        twitter      = UserCustomField.create(:name => 'Twitter',             :field_format => 'string',  :position => pos += 1, :is_for_new => false, :regexp => '^@?[A-Za-z0-9_]+$',        :hint => 'e.g. AndriyLesyuk')
        linkedin     = UserCustomField.create(:name => 'LinkedIn',            :field_format => 'link',    :position => pos += 1, :is_for_new => false)

        if project.has_attribute?(:visible)
            project.update_attribute(:visible, false)
        end

        if ActiveRecord::Base.connection.table_exists?('extended_profiles')
            User.connection.select_all("SELECT user_id, company, company_site, position, project_id, personal_site, blog, facebook, twitter, linkedin
                                        FROM extended_profiles").each do |profile|
                if user = User.find_by_id(profile['user_id'])
                    CustomValue.create(:custom_field => company,      :customized => user, :value => profile['company'])       if profile['company'].present?
                    CustomValue.create(:custom_field => company_site, :customized => user, :value => profile['company_site'])  if profile['company_site'].present?
                    CustomValue.create(:custom_field => position,     :customized => user, :value => profile['position'])      if profile['position'].present?
                    CustomValue.create(:custom_field => project,      :customized => user, :value => profile['project_id'])    if profile['project_id'].present?
                    CustomValue.create(:custom_field => website,      :customized => user, :value => profile['personal_site']) if profile['personal_site'].present?
                    CustomValue.create(:custom_field => blog,         :customized => user, :value => profile['blog'])          if profile['blog'].present?
                    CustomValue.create(:custom_field => facebook,     :customized => user, :value => profile['facebook'])      if profile['facebook'].present?
                    CustomValue.create(:custom_field => twitter,      :customized => user, :value => profile['twitter'])       if profile['twitter'].present?
                    CustomValue.create(:custom_field => linkedin,     :customized => user, :value => profile['linkedin'])      if profile['linkedin'].present?
                end
            end
        end
    end

end
