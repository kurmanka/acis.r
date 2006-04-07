

// toggle visibility 

function toggle( targetId ){  // stolen from http://www.happycog.com/j/h.js

  if (document.getElementById){
          var target = document.getElementById( targetId );
                          if (target.style.display == "none"){
                                  target.style.display = "";
                          } else {
                                  target.style.display = "none";
                          }
          }
}

function getRef(obj) {
  if ( typeof obj == "string" && document.getElementById ) {
    obj= document.getElementById(obj);
  }
  return obj;
}




function show( targetId ) {
  if ( document.getElementById ) {
    var target = document.getElementById( targetId );
    if ( target ) { target.style.display = ""; }
  }
}

function hide( targetId ) {
  if ( document.getElementById ) {
    var target = document.getElementById( targetId );
    if ( target ) { target.style.display = "none"; }
  }
}


var origClass;

function ULL( a ) {
  origClass = a.className;
  a.className='hovering ' + a.className;
}

function HUL( a ) {
  a.className = origClass;
}


// toggle_class( id, cla ) -- puts string cla
// into the elements' className if its not present
// or removes it if it is.

function toggle_class( id, cla ) {
  var o = getRef( id );
  var class_list;
  if ( o ) {

     /// simple cases
     if ( ! o.className
          || o.className == '' ) {
          o.className = cla; 
	  return;
     }
  
     if ( o.className == cla ) { 
       o.className='';
     } 

     class_list = o.className.split( ' ' );

  } else { return; }

  var already_there = false;
  var its_index;
  for ( var i=0; i < class_list.length; i++ ) {
     if ( class_list[i] == cla ) {
       already_there = true;
       its_index = i;
       break;
     }      
  } 

  if ( already_there ) {
     class_list.splice(its_index, 1);
     
  } else {
     class_list.push( cla );
  }   

  o.className = class_list.join(" ");
  return;
}

// set_class_if() func
// Ensures that the element identified by id either has
// cla as one of its classes or not, depending on the 
// checked logical value.

function set_class_if( id, cla, checked ) {
  var o = getRef( id );
  var class_list;
  if ( o ) {

      /// simple cases
//      if ( ! o.className ) { return; }
      if (    o.className == '' 
	   || o.className == cla ) {
	  
	  if ( checked ) {
	      o.className = cla;
	  } else {
	      o.className = '';
	  }
	  return;
     }
  
     class_list = o.className . split( ' ' );
  }
  var already_there = false;
  var its_index;
  var with_cla    ='';
  var without_cla ='';

  for ( var i=0; i < class_list.length; i++ ) {
      var klass = class_list[i];
      if ( klass ) {
	  with_cla = with_cla + klass + " ";
	  if ( klass == cla ) {
	      already_there = true;
	      its_index = i;
	  } else {
	      without_cla = without_cla + klass + " ";
	  }
      }
  } 

  if ( ! already_there ) {
      with_cla = with_cla + cla;
  }


  if ( already_there ) {
      if ( ! checked ) {
	  o.className = without_cla;
	  return;
      }
     
  } else {
      if ( checked ) {
	  o.className = with_cla;
	  return;
      }
  }   

  return;
}

var item_label_click = false;

function item_checkbox_changed ( rowid, c ) {
  set_class_if( rowid, "select", c.checked );
  /*c.blur();*/
}

function item_checkbox_blur ( rowid, c ) {
  set_class_if( rowid, "select", c.checked );
}





var formChanged=false;
var formChangedName;


function a_parameter_change( fname ) {
  formChanged = true;
  formChangedName = fname;
//  var form = document.forms[fname];
//  form.className='changed ' + className;
}

function form_submit() {
  formChanged = false;
}

function check_form_changes() {
  if ( formChanged && formChangedName ) {
    var save = confirm(  "Save your changes before you leave?\n\nPress OK to save." );
    
    if ( save ) {
      formChanged = false;
      Submit( formChangedName );
      return( false );
    }
  }
  formChanged = false;
  return true;
}



function set_parameter ( formname, par, val ) {
 var form = document.forms[formname];
 form.reset;
 if ( form.elements[par] ) {
   form.elements[par].value = val;
   formChanged = true;
   formChangedName = formname;
 } else {
   alert( "INTERNAL ERROR\nNo parameter '" + par + "'." );
 }
}


function Submit ( formname ) {
  var form = document.forms[formname];
  form.submit();
}

function give_focus_to_first_control () {
  if ( document.forms[0] && document.forms[0].elements[0] ) {
    document.forms[0].elements[0].focus();
  }
}


function install_ahref_onclick_form_change_check () {
  
}

function Obfuscate( b, a, attr ) {
  document.write( '<a ' + ( attr ? ( attr ) : '' ) 
  + 'href="mailto:' + a + '&#64;' + b + '">' + a +  '&#64;' + b + '</a>' );
}

function Obfuscate_with_body( b, a, attr, body ) {
  document.write( '<a ' + ( attr ? ( attr ) : '' ) 
  + 'href="mailto:' + a + '&#64;' + b + '">' + body + '</a>' );
}



// From ALA's Paul Bowden 
//   http://alistapart.com/articles/alternate/
// with small modifications
 
function setActiveStyleSheet(title) {
   if (    ! document.getElementsByTagName 
        || ! document.getElementsByTagName("link") ) { 
     return;
   }

   var i, a;
   var links = document.getElementsByTagName("link");
   if ( !links.length ) return;

   for ( i=0; links.length > i; i++ ) {
     a = links[i];
     if ( a.getAttribute("rel").indexOf("style") != -1
          && a.getAttribute("title") ) {
       a.disabled = true;
       if ( a.getAttribute("title") == title ) {
          a.disabled = false;
          setCookie("style", title, 365);
       }
     }
   }  
}



function setCookie( name, value, days, path, domain ) {
  if (days) {
    var date = new Date();
    date.setTime(date.getTime()+(days*24*60*60*1000));
    var expires = "; expires="+date.toGMTString();

  } else {
    expires = "";
  }
  document.cookie = name+"="+ escape(value) 
     + expires
     + ( path ? "; path="+path : "" )
     + ( domain ? ";domain="+domain : "");
}


function readCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for ( var i=0; i < ca.length; i++ ) {
    var c = ca[i];
    while ( c.charAt(0)==' ' ) c = c.substring(1,c.length);
    if ( c.indexOf(nameEQ) == 0 ) return c.substring(nameEQ.length,c.length);
  }
  return null;
}

function getCookie( name ) {  // from meetup.com/scripts/global.js
  var start = document.cookie.indexOf( name + "=" );
  var len = start + name.length + 1;
  if ( ( !start ) && ( name != document.cookie.substring( 0, name.length ) ) ) {
    return null;
  }
  if ( start == -1 ) return null;
  var end = document.cookie.indexOf( ";", len );
  if ( end == -1 ) end = document.cookie.length;
  return unescape( document.cookie.substring( len, end ) );
}



function onload_show_switcher () { 
  if ( document.getElementsByTagName ) { 
     show( "styleSwitch" );
  }
}

function init_set_style () { 
  var cookie = getCookie("style");
  if ( cookie ) {
    setActiveStyleSheet( cookie );
  }
}

init_set_style();



/******   installation tool   *****************/         

// from http://simon.incutio.com/archive/2004/05/26/addLoadEvent
function addLoadEvent(func) {
    var oldonload = window.onload;
    if (typeof oldonload != 'function') {
        window.onload = func;
    } else {
        window.onload = function() {
            oldonload();
            func();
        }
    }
}

