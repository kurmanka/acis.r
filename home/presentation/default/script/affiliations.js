function show_instructions() {
    hide( "show-instructions-trigger" );
    show( 'search-instructions' );
}

function hide_instructions() {
    hide( 'search-instructions' );
    show( "show-instructions-trigger" );
}

function search_focus() {
    var inp = document.searchform["search-what"]; 
    inp.focus();
}

function search_clear_and_focus() {
    var inp = document.searchform["search-what"]; 
    inp.value = "";
    inp.focus();
}
