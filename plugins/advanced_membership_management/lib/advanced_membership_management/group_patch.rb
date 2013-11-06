require_dependency 'group'

module AdvancedMembershipManagement
  
  module GroupPatch
    
    def self.included(base) # :nodoc:

      # Same as typing in the class 
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        has_one :automatic_membership, :dependent => :destroy, :include => :automatic_membership_roles, :foreign_key => 'user_id'
        has_many :automatic_membership_roles, :through => :automatic_membership
      end

    end
    
  end
end

# Guards against including the module multiple time (like in tests)
# and registering multiple callbacks
unless Group.included_modules.include? AdvancedMembershipManagement::GroupPatch
  Group.send(:include, AdvancedMembershipManagement::GroupPatch)
end