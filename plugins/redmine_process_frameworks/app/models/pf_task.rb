class PfTask < ActiveRecord::Base
  belongs_to :action , :class_name => "Action" , :foreign_key => "action_id"
  
  def attachments
       PfAttachment.find(:all,:conditions=>["foreign_id=? and type=?",self.id,"PfTask"])
  end
  
   acts_as_list :scope => 'action_id = #{self.action_id}'
   
    
   def self.to_p_name
    return l(:label_subtask_plural)
  end
  
   
   def self.get_parent_name
     return 'Action'
 end
 
 
 def self.get_sub_name
     return ''
   end
end
