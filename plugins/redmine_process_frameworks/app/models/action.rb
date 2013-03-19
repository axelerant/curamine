class Action < ActiveRecord::Base
  belongs_to :activity , :class_name => "Activity" , :foreign_key => "activity_id"
  has_many :pf_tasks , :class_name => "PfTask" , :dependent => :destroy , :foreign_key => "action_id",  :order => 'position ASC'
  
    acts_as_list :scope => 'activity_id =#{self.activity_id}'
   
  def attachments
       PfAttachment.find(:all,:conditions=>["foreign_id=? and type=?",self.id,"Action"])
  end
   
  def self.to_p_name
    return l(:field_issue)
  end
  
   
  def self.get_parent_name
    return 'Activity'
  end
  
  def self.get_sub_name
    return 'PfTask'
  end
  
end
