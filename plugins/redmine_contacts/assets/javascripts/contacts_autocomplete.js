function initContactsAutocomplete(fieldName, sourceUrl, selectUrl) {
  var fieldId = '#' + fieldName.split('[').join('_').split('__').join('_').split(']').join('');
  var spanId = fieldId + '_selected_contact';
  var linkId = fieldId + '_edit_link';

  function selectContact( contact ) {
    if (!selectUrl || !selectUrl.length)  {
      $(spanId).text( contact.name );
      $(spanId).show();
      $(spanId).scrollTop( 0 );
      $(fieldId).hide();
      $(linkId).show();
      $(fieldId + '_add_link').hide();
    } else {
      $.ajax({
         url: selectUrl,
         type: 'POST',
         data: {id: contact.id}
      });
    }
  };

  $(fieldId).autocomplete({
    source: sourceUrl,
    search: function(){$(this).addClass('ajax-loading');},
    response: function(){$(this).removeClass('ajax-loading');},
    change: function(event,ui){
      $(this).val((ui.item ? ui.item.id : ''));
    },
    select: function( event, ui ) {
      selectContact( ui.item ?
          ui.item:
          'Nothing selected, input was ' + this.value);
      return false;
    },
    minLength: 0
  })
  // .focus(function(){$(this).autocomplete("search");})
  .data('ui-autocomplete')._renderItem = function( ul, item ) {
    return $('<li>')
      .append('<a>' + item.avatar + '&nbsp;' + item.name + (item.company.length != 0 ? ' (' + item.company + ') ' : '') + '</a>')
      .appendTo( ul );
  };

}