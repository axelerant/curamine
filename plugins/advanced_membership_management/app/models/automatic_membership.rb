class AutomaticMembership < ActiveRecord::Base
  unloadable
  belongs_to :user
  has_many :automatic_membership_roles, :dependent => :destroy
  has_many :roles, :through => :automatic_membership_roles
  
  validates :user_id, :uniqueness => true, :presence => true
  validate :validate_role
  
  def role
  end
  
  def role=
  end
  
  alias :base_role_ids= :role_ids=
  def role_ids=(arg)
    ids = (arg || []).collect(&:to_i) - [0]
    
    # Add new roles
    ids.each {|id| automatic_membership_roles << AutomaticMembershipRole.new(:role_id => id) }
    # Remove roles (Rails' #role_ids= will not trigger MemberRole#on_destroy)
    automatic_membership_roles_to_destroy = automatic_membership_roles.select {|mr| !ids.include?(mr.role_id)}
    if automatic_membership_roles_to_destroy.any?
      automatic_membership_roles_to_destroy.each(&:destroy)
    end
    if ids.empty?
      destroy
      return []
    end
  end
  
  protected
  
  def validate_role
    errors.add_on_empty :role if automatic_membership_roles.empty? && roles.empty?
  end
end
