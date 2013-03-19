var mpx = 0;
var mpy = 0;
var obj=0;

function show_hide_div()
{
   
    var theDiv = document.getElementById("mdiv");
    if(theDiv.style.visibility == "hidden")
        theDiv.style.visibility = "visible";
    else
        theDiv.style.visibility = "hidden";
       
}

function finddiv(ev,mdiv){
  obj  = document.getElementById(mdiv);
  ev = ev||window.event;
  x = ev.clientX-parseInt(obj.style.left);
  y = ev.clientY-parseInt(obj.style.top);

}

function movediv(ev){
 if(obj == 0){
  return false;
 }
 else{

   ev = ev||window.event;
    var mousePos = mouseCoords(ev);
    if(mousePos.y < 10)return ;
    mpx = mousePos.x - x;
    mpy = mousePos.y - y;
   
    obj.style.left = mpx+"px";
    obj.style.top = mpy+"px";
 }
}

function mouseCoords(ev){
    if(ev.pageX||ev.pageY){return {x:ev.pageX, y:ev.pageY};}
    return {x:ev.clientX + document.documentElement.scrollLeft,y:ev.clientY + document.documentElement.scrollTop}
}
 