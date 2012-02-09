
// if user unchecked the "dead" checkbox, disable the date controls

function dead_checkbox_click( box ) {
    //console.log( box );
    var e = document.getElementById( 'date-y' );
    if (e) { e.disabled = ! box.checked; }
    e = document.getElementById( 'date-m' );
    if (e) { e.disabled = ! box.checked; }
    e = document.getElementById( 'date-d' );
    if (e) { e.disabled = ! box.checked; }
}