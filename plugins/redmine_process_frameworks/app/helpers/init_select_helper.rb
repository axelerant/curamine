module InitSelectHelper
  
  def link_my_remote(type)
    link_to_remote type[:name],:update => "show_details",
      :url => {:project_id => @project,:action => "show_details",
      :plat=>type[:id],:name=>type.class.name},:before => "ClickLink('checkboxs','a');this.style.background = '#80609F';this.style.color='#ffffff';"
  end
  
  
  
end
