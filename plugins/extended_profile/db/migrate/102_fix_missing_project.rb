class FixMissingProject < ActiveRecord::Migration

    def self.up
        custom_field = CustomField.find_by_name_and_type('Project of interest', 'UserCustomField')
        if custom_field.is_required?
            User.find(:all, :conditions => { :type => 'User' }).each do |user|
                interest_project = user.custom_field_values.detect{ |custom_value| custom_value.custom_field_id == custom_field.id }
                if interest_project && interest_project.value.nil?
                    project = (user.memberships.collect(&:project).first || Project.all(:conditions => Project.allowed_to_condition(user, :view_project), :order => 'name').first)
                    if project
                        interest_project.value = project.id
                        interest_project.save
                    end
                end
            end
        end
    end

end
