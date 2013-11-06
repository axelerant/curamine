ActionDispatch::Callbacks.to_prepare do
  # require_dependency to refresh in development
  # require to load only when server starts
  require_dependency 'advanced_membership_management/member_patch'
  require_dependency 'advanced_membership_management/project_patch'
  require_dependency 'advanced_membership_management/user_patch'
  require_dependency 'advanced_membership_management/group_patch'
  require_dependency 'advanced_membership_management/append_stylesheet_hook_listener'
end

Redmine::Plugin.register :advanced_membership_management do
  name 'Advanced Membership Management plugin'
  author 'Bishma Stornelli'
  description %Q{
    Este plugin permite:
      1. Auto asignar recursos a subproyectos existentes cuando se asignan al padre.
      2. Auto asignar recursos asignados a un proyecto en nuevos subproyectos.
      3. Definir usuarios/grupos/roles para autoasignar en todo nuevo proyecto creado. 
  }
  version '0.0.1'
  
  menu :admin_menu, 
        :automatic_memberships, 
        { :controller => 'automatic_memberships', :action => 'index' }, 
        :caption => :label_automatic_memberships
end
