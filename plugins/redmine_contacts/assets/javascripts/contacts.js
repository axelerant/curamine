// Copyright (c) 2011-2013 Kirill Bezrukov

var noteFileFieldCount = 1;

function addNoteFileField() {
	if (noteFileFieldCount >= 10) return false
	noteFileFieldCount++;
	var f = document.createElement("input");
	f.type = "file";
	f.name = "note_attachments[" + noteFileFieldCount + "][file]";
	f.size = 30;
	var d = document.createElement("input");
	d.type = "text";
	d.name = "note_attachments[" + noteFileFieldCount + "][description]";
	d.size = 60;

	p = document.getElementById("note_attachments_fields");
	p.appendChild(document.createElement("br"));
	p.appendChild(f);
	p.appendChild(d);
}

function updateCustomForm(url, form) {
  $.ajax({
    url: url,
    type: 'post',
    data: $(form).serialize()
  });
}

function toggleContact(event, element)
{
	if (event.shiftKey==1)
	{
		if (element.checked) {
			checkAllContacts($$('.contacts.index td.checkbox input'));
		}
		else
		{
			uncheckAllContacts($$('.contacts.index td.checkbox input'));
		}
	}
	else
	{
		Element.up(element, 'tr').toggleClassName('context-menu-selection');
	}
}


// Observ field function

(function( $ ){

  jQuery.fn.observe_field = function(frequency, callback) {

    frequency = frequency * 100; // translate to milliseconds

    return this.each(function(){
      var $this = $(this);
      var prev = $this.val();

      var check = function() {
        if(removed()){ // if removed clear the interval and don't fire the callback
          if(ti) clearInterval(ti);
          return;
        }

        var val = $this.val();
        if(prev != val){
          prev = val;
          $this.map(callback); // invokes the callback on $this
        }
      };

      var removed = function() {
        return $this.closest('html').length == 0
      };

      var reset = function() {
        if(ti){
          clearInterval(ti);
          ti = setInterval(check, frequency);
        }
      };

      check();
      var ti = setInterval(check, frequency); // invoke check periodically

      // reset counter after user interaction
      $this.bind('keyup click mousemove', reset); //mousemove is for selects
    });

  };

})( jQuery );