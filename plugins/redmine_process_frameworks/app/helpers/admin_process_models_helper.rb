module AdminProcessModelsHelper

  
  def admin_models_tabs
    tabs = [{:name => 'ProcessModel', :partial => 'admin_process_models/index', :label => :label_model},
            {:name => 'Activity', :partial => 'admin_process_models/index', :label => :field_version},
            {:name => 'Action', :partial => 'admin_process_models/index', :label => :field_issue},
            {:name => 'PfTask', :partial => 'admin_process_models/index', :label => :label_subtask_plural}
            ]
  end
  
  
  def check_used(elem)
    not_used = true
    case elem
      when ProcessModel
        not_used = Project.find_by_model_id(elem.id).nil?
      when Activity
        not_used =(elem.model_id.nil? || elem.model_id<0)
      when Action
        not_used = (elem.activity_id.nil? || elem.activity_id<0)
      when PfTask
         not_used = (elem.action_id.nil? || elem.action_id<0)
     end
     return  !not_used
 end
 
 
  def my_check_image(checked=true)
    if checked
      image_tag 'toggle_check.png'
    else
      image_tag 'close.png'
    end
  end


 def link_to_my_pagi(list)
    list_count = list.length
    list_pages = Paginator.new self,list_count, per_page_option, params['page']
    pagination_links_full list_pages, list_counts
 end
  
  
end
