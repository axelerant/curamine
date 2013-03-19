namespace :ProcessFramework do
  require 'rexml/document'
  templates_dir =  File.join(File.dirname(__FILE__),"../templates")
  
  desc   "import default templates for process framework"
  task :import_templates  => :environment do 
    file_dir = templates_dir+'/*.xml'
    FileList[file_dir].each do |xml_file| 
      uploaded_file = xml_file
      doc = REXML::Document.new(File.open(xml_file))
      position_model = ProcessModel.find(:first, :order=> "position DESC")
      model_position = position_model.nil?? 1: (position_model.position+1) 
      doc.elements.each("process_model") do |e| 
        if ProcessModel.find_by_name(e.attributes["name"]).nil?         
          new_process_model = ProcessModel.new
          new_process_model.name = e.attributes["name"]
          new_process_model.author_id = User.current.id
          new_process_model.date = Time.now
          new_process_model.description = e.text
          new_process_model.position = model_position
          new_process_model.save
          ++ model_position
          activies = e.get_elements("activity")
          activity_position =1
          activies.each do |acty|
            new_activity = Activity.new
            new_activity.name = acty.attributes["name"]
            new_activity.description = acty.text
            new_activity.model_id = new_process_model.id
            new_activity.position= activity_position
            ++activity_position
            new_activity.save
            action_position = 1
            actions = acty.get_elements("action")
            actions.each do |acns|
              new_action = Action.new
              new_action.name = acns.attributes["name"]
              new_action.description = acns.text
              new_action.activity_id = new_activity.id
              new_action.position = action_position
              new_action.save
              ++action_position 
              task_position = 1
              tasks = acns.get_elements("task")
              tasks.each do |task|
                new_task = PfTask.new
                new_task.name = task.attributes["name"]
                new_task.description = task.text
                new_task.action_id = new_action.id
                new_task.position = task_position
                ++task_position
                new_task.save
              end
            end
          end
           puts  "import model: "+ e.text + " succeed!"
        else     
          puts  "exists model: "+e.text
          next
        end
          puts  "import file: "+ xml_file + " succeed!"
      end
      puts "imort "+xml_file+ "is done!"
    end
      puts  "import is done!"
  end
end