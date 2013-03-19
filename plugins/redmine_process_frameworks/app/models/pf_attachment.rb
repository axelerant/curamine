class PfAttachment < ActiveRecord::Base
  validates_inclusion_of :type,:in => ["Action","PfTask"], :message => "should be Task or Action"
  
end
