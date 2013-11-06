require_dependency 'member'

module AdvancedMembershipManagement
  
  module MemberPatch
    
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      # Same as typing in the class 
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        after_initialize :initialize_roles_changes
        after_create :add_memberships_to_subprojects
        after_update :update_roles_of_subprojects_memberships
        after_destroy :remove_roles_in_subprojects
      end

    end
    
    module ClassMethods
    end
    
    module InstanceMethods
      
      attr_accessor :roles_changes
      
      # This will update the KanbanIssues associated to the issue
      def add_memberships_to_subprojects
        # Debo anadir solo los roles no heredados pues al crear el miembro del grupo
        # los usuarios heredan esos roles
        roles_changes[:added] ||= member_roles.where(:role_id => role_ids, :inherited_from => nil).collect(&:role_id)  
        roles_changes[:removed] ||= []
        logger.debug "add_memberships_to_subprojects: Adding memberships #{roles_changes[:added].inspect} and removing #{roles_changes[:removed].inspect} to subprojects of #{project}"
        if roles_changes[:added].any? 
          # Si efectivamente hay roles agregados que no son por herencia
          # las duplico en los subprojectos
          
          subprojects = Project.where(:parent_id => project)
        
          subprojects.each do |subproject|
            #puts "Iterating on project #{project.name}"
            
            # Existe o no una membresia en el subproyecto asociada a este usuario?
            subproject_membership = subproject.memberships.find_by_user_id(user_id)
            
            if subproject_membership.nil?
              # Si no existe tengo que crear una
  
              new_member = Member.new(
                :role_ids => self.roles_changes[:added] , 
                :user_id => self.user_id
              )
              #new_member.roles_changes = self.roles_changes # Make the correct changes propagate
              #project.members << new_member
              
              subproject.members << new_member
              
              # Cuando se crea el miembro, se dispara el mismo trigger y se debe asegurar que
              # agregue todos los roles que se agregaron a el
            else
              # Si ya existe una membresia, tengo que actualizarla
              
              subproject_membership.roles_changes = roles_changes
              
              subproject_membership.update_role_idsss
              
            end
          end
        end
        
      end
      
      def update_roles_of_subprojects_memberships
        
        
        # Cuando se actualiza una membresia, puede ser que los cambios que hayan
        # que hacer ya hayan sido asignados anteriormente (por eso el ||=)
        roles_ids_not_inherited = member_roles.where(:role_id => role_ids, :inherited_from => nil).collect(&:role_id)
        roles_changes[:added] ||= roles_ids_not_inherited - roles_changes[:original]
        roles_changes[:removed] ||= roles_changes[:original] - roles_ids_not_inherited
        
        logger.debug "update_roles_of_subprojects_memberships: Adding memberships #{roles_changes[:added].inspect} and removing #{roles_changes[:removed].inspect} to subprojects of #{project}"
        
        subprojects = Project.where(:parent_id => self.project)
        
        subprojects.each do |subproject|
          
          subproject_membership = subproject.memberships.find_by_user_id(self.user_id)
          
          if subproject_membership.nil?
            # Si en el subproyecto no existe una membresia debo crearla
            # pero para ello debo verificar si hay algun role que agregar
            
            if self.roles_changes[:added].empty?
              # Si no hay ninguno que agregar, entonces no creo la membresia pero
              # debo hacer que los cambios se reflejen en los hijos del subproyecto
              
              subprojects.concat Project.where(:parent_id => subproject.id)
              
            else
              # Si efectivamente hay roles que agregar, entonces creo la membresia

              new_member = Member.new(
                :role_ids => roles_changes[:added] , 
                :user_id => user_id
              )
              
              # Debo asegurarme de que agregue y remueva los roles cuando se dispare el callback en el nuevo miembro
              new_member.roles_changes = roles_changes 
              subproject.members << new_member 
            end
            
          else
            # Si ya existe una membresia entonces actualizo sus roles
            
            subproject_membership.roles_changes = roles_changes            
            subproject_membership.update_role_idsss
            
          end
        end
      end
      
      def remove_roles_in_subprojects
        
        # Cuando se elimina un miembro deben eliminarse todos los roles no heredados
        # Si hay alguno heredado se eliminara cuando se elimine el miembro del que se heredaron
        self.roles_changes[:added] ||= []
        self.roles_changes[:removed] = self.roles_changes[:original]
        logger.debug "remove_roles_in_subprojects: Adding memberships #{roles_changes[:added].inspect} and removing #{roles_changes[:removed].inspect} to subprojects of #{project}"
        subprojects = Project.where(:parent_id => self.project)
        subprojects.each do |subproject|
          
          subproject_membership = subproject.memberships.find_by_user_id(self.user_id)
          
          if subproject_membership.nil?
            # Si el subproyecto no tiene una membresia, debo propagar los
            # cambios a los hijos del subproyecto
            
            subprojects.concat Project.where(:parent_id => subproject.id)
            
          else            
            # Si ya existe una membresia, debo eliminar solo los roles
            # que fueron eliminados de self
            
            subproject_membership.roles_changes = roles_changes
            subproject_membership.update_role_idsss
            
          end
        end
      end
      
      def initialize_roles_changes
        @roles_changes = { original: self.role_ids }
      end
      
      def update_role_idsss
        self.role_ids = (self.role_ids | self.roles_changes[:added]) - self.roles_changes[:removed]
        self.save
      end
    end  
  end
end

# Guards against including the module multiple time (like in tests)
# and registering multiple callbacks
unless Member.included_modules.include? AdvancedMembershipManagement::MemberPatch
  Member.send(:include, AdvancedMembershipManagement::MemberPatch)
end