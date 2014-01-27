module InitSelectHelper
  
  def link_my_remote(type)
    link_to type[:name], 
      { :project_id => @project, :action => "show_details", :plat=>type[:id], :type=>type.class.name,:name=>type.class.name},
      :remote => true,
      :method => :post,
      "class" => "link-name", 
      "update-target" => "show_details",
      "script-before" => "ClickLink('checkboxs','a');this.style.background = '#80609F';this.style.color='#ffffff';"
  end
end
