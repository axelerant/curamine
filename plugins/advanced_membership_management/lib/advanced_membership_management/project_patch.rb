require_dependency 'project'

module AdvancedMembershipManagement
  
  module ProjectPatch
    
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      # Same as typing in the class 
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        # Hay un error con esta linea. AL parecer al momento de llamar el callback, el padre es nil
        alias_method_chain :set_parent!, :members_copied
        after_create :add_automatic_memberships
      end

    end
    
    module ClassMethods
    end
    
    module InstanceMethods
      
      def set_parent_with_members_copied!(p)
        p_id_before = parent_id # Must be captured before setting parent because it doesn't save parent_id_was correctly
        set_parent = set_parent_without_members_copied!(p)
        if set_parent && p && p_id_before != parent_id
          # Inherit only when there's a new parent (not nil)
          self.memberships.destroy_all unless self.memberships.nil?
          copy_members(p)
        end
        set_parent
      end
      
      def add_automatic_memberships
        AutomaticMembership.all.each do |am|
          logger.info "Adding user #{am.user} as member in new project with roles #{am.roles.pluck(:name).join(", ")}"
          m = Member.new(:user_id => am.user_id, :role_ids => am.role_ids)
          members << m
        end
      end
      
    end  
  end
end

# Guards against including the module multiple time (like in tests)
# and registering multiple callbacks
unless Project.included_modules.include? AdvancedMembershipManagement::ProjectPatch
  Project.send(:include, AdvancedMembershipManagement::ProjectPatch)
end