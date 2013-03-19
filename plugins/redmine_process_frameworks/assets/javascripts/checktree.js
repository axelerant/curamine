
function Ob(o){
 var o=document.getElementById(o)?document.getElementById(o):o;
 return o;
}
function Hd(o) {
 Ob(o).style.display="none";
}
function Sw(o) {
 Ob(o).style.display="";
}
function ExCls(o,a,b,n){
 var o=Ob(o);
 for(i=0;i<n;i++) {o=o.parentNode;}
 o.className=o.className==a?b:a;
}

function CheckList(id,TagName1,TagName2){
	this.id = id;
	this.inputs =  Ob(id).getElementsByTagName(TagName1);
	for(var i=0; i<this.inputs.length; i++){ 
	    var input = this.inputs[i] ;
	    if(input.type == 'checkbox'){
	        input.onclick = ClickInput; 
	    } 
	} 	
}
function ClickLink(id,TagName){
	var links = Ob(id).getElementsByTagName(TagName);
	for(var i=0; i<links.length; i++){ 
	      links[i].style.background = "";
		  links[i].style.color = "#2A5685";
	}
}

function ClickInput(){ 
	
	    var li = this.parentNode; 
	    var inputs = li.getElementsByTagName('input') 
	    for(var i=0; i<inputs.length; i++){ 
	        var input = inputs[i] ;
	        if(input.type == 'checkbox'){ 
	            input.checked = this.checked; 
	        } 
	    } 
		var li = li.parentNode.parentNode; 
		 while(li.tagName.toLowerCase() == 'li'){ 
		    var input = li.childNodes[1] ;
		    if(input.tagName.toLowerCase() == 'input'){ 
		        if (this.checked !="") {
					input.checked = 'true';
				}
		    } 
		    li = li.parentNode.parentNode ;
		} 
} 

function CheckTreeMenu(id,TagName0) {
  this.id=id;
  this.TagName0=TagName0==""?"li":TagName0;
  this.AllNodes = Ob(this.id).getElementsByTagName(TagName0);
  
  this.InitCss = function (ClassName0,ClassName1,ClassName2,ImgUrl) {
  	var links = Ob('checkboxs').getElementsByTagName('a');
	links[0].style.background = "#80609F";
	links[0].style.color='#ffffff'
	  this.ClassName0=ClassName0;
	  this.ClassName1=ClassName1;
	  this.ClassName2=ClassName2;
	  this.ImgUrl=ImgUrl || "../images/s.gif";
	  this.ImgBlankA ="<img src=\""+this.ImgUrl+"\" class=\"s\" onclick=\"ExCls(this,'"+ClassName0+"','"+ClassName1+"',1);\" alt=\"展开/折叠\" />";
	  this.ImgBlankB ="<img src=\""+this.ImgUrl+"\" class=\"s\" />";
	  
	  for (i=0;i<this.AllNodes.length;i++ ) {
	   this.AllNodes[i].className==""?this.AllNodes[i].className=ClassName0:"";
	   this.AllNodes[i].innerHTML=(this.AllNodes[i].className==ClassName2?this.ImgBlankB:this.ImgBlankA)+this.AllNodes[i].innerHTML;
	   }
  	 
   }
	 this.SetNodes = function (n) {
	  var sClsName= n==0?this.ClassName0:this.ClassName1;
	  for (i=0;i<this.AllNodes.length;i++ ) {
	   this.AllNodes[i].className==this.ClassName2?"":this.AllNodes[i].className=sClsName;
	  }
	 }
      
}
