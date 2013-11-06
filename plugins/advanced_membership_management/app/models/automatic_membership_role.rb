class AutomaticMembershipRole < ActiveRecord::Base
  unloadable
  belongs_to :automatic_membership
  belongs_to :role
  
  #after_destroy :remove_automatic_membership_if_empty
  
  validates_presence_of :role
  validates_uniqueness_of :role_id, :scope => :automatic_membership_id
  validates :role_id, :inclusion => { :in => Role.givable.pluck(:id) }
  
  private
  
  def remove_automatic_membership_if_empty
    automatic_membership.destroy if automatic_membership.roles.empty?
  end
end
