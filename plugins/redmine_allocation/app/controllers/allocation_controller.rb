class AllocationController < ApplicationController
  before_filter :find_project
  menu_item :overview
  include Allocation::Allocation

  def by_project
    @projects = Project.visible.active.find :all,
                                            :conditions => @project.project_condition(true),
                                            :include => [:members => :user],
                                            :order => "#{Project.table_name}.lft"
  end

  def by_user
    @months = months
    user_group_field = Setting.plugin_redmine_allocation['users_custom_field']
    project_group_field = Setting.plugin_redmine_allocation['projects_custom_field']
    subproject_users = User.active.find :all,
                                        :select => "DISTINCT #{User.table_name}.*",
                                        :joins => { :members => :project },
                                        :include => :members,
                                        :conditions => @project.project_condition(true)
    if user_group_field.present? and project_group_field.present?
      group = @project.custom_value_for(project_group_field)
      quoted_group = CustomValue.connection.quote group
      group_users = User.active.find :all,
                                     :joins => { :custom_values => :custom_field },
                                     :include => :members,
                                     :conditions => "#{CustomField.table_name}.id = #{user_group_field}"
                                                    " AND #{CustomValue.table_name}.value = #{quoted_group}"
      outside_users = subproject_users - group_users
      group_allocation = allocation_by_months(group_users, @months)
      outside_allocation = allocation_by_months(outside_users, @months)
      @allocation = [[:"allocation.label_group_allocation", group_allocation],
                     [:"allocation.label_outside_allocation", outside_allocation]]
    else
      all_allocation = allocation_by_months(subproject_users, @months)
      @allocation = [[:"allocation.label_all_allocation", all_allocation]]
    end
  end
end
