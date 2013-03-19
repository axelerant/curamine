class ProcessModel < ActiveRecord::Base
  has_many :activities , :class_name => "Activity" , :dependent => :destroy , :foreign_key => "model_id",  :order => 'position ASC'
  belongs_to :projects, :class_name => "Project", :dependent => :destroy, :foreign_key => "model_id"
  belongs_to :users,:class_name => "User" , :dependent => :destroy, :foreign_key => "author_id"
  
   acts_as_list 
  
  
  def get_author
    User.find(self.author_id)
  end
  
   
  def  self.to_p_name
    return l(:label_model)
  end
  
   

  def self.get_sub_name
    return 'Activity'
  end
  
end

