class Activity < ActiveRecord::Base
  belongs_to :process_model , :class_name => "ProcessModel" ,
       :foreign_key => "model_id"
  has_many  :actions , :class_name => "Action" , 
       :dependent => :destroy , :foreign_key => "activity_id",  :order => 'position ASC'
       
   acts_as_list :scope => 'model_id = #{self.model_id}'
   
    
   def self.to_p_name
    return l(:field_version)
   end
  
   
   def self.get_parent_name
    return 'ProcessModel'
   end
  
   def self.get_sub_name
    return 'Action'
   end
end
