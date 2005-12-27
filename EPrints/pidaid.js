/* -*- mode:java -*- */
/* my emacs has no javascript mode, but this mode works well enough */
/* $Id: pidaid.js,v 2.0 2005/12/27 19:47:36 ivan Exp $ */


var textMenuPrompt = 'Is this someone we know?';
var textIdPrompt   = 'Id "#id#" belongs to:';
var textIdUnknown  = 'No such record: id "#id#" is not known.';
var textIdUnknownHint = "No such record: id unknown";
var textChoosePersonHint      = 'choose this person';
var textThisPersonDetailsHint = "this person's details";
var textPersonHomepageHint    = "this person's homepage";
var textUndoButton            = 'undo choice';

var reWhitespace = /^\s*(.*\S)\s*$/;
var reEmail = /^[\&\+a-z\d\-\.\=\_]+\@([a-z\d\-\_]+\.)+[a-z]{2,}$/i;
var reId    = /^p[a-z]+\d+$/i;


var base_url='/perl/pidaid';
var img_base='/';
var d = document;
var debug;

/*
 A group of input controls represents one person, i.e. one author or
 editor.  There are usually several groups of controls on the page.

 We keep some information about each control group in the name_groups
 array.
*/

var name_groups = new Array;
var name_group = {};   // reference to the current control group
var name_group_prefix; // name of the current control group

var cache = {};
var last_request_data;
var menu_for_group, menu_for_request_data;
var undo_button_for_group;

/************************************************ 
                     TOOLS 
*************************************************/


// little string-related tools, etc

function is_email( v ) {
    return reEmail.test( v );
}

function is_id( v ) {
    return reId.test( v );
}

function make_text( message, id ){
    message = message.replace( /#id#/, id );
    return message;
}

function normalize( str ) {
    var res;
    if ( typeof str != 'string' ) { 
        return null;
    }
    if ( reWhitespace.test( str ) ) {
        res = RegExp.$1;
        res = res.replace( /\s+/g, ' ' );
    } else { 
        res = ''; 
    }
    return res;
}

// a little debugging support func
var debug_list = new Array;
function DEBUG ( msg ) {
   if ( debug 
        && debug_list.push ) {
       debug_list.push( msg );
       if ( debug_list.length >= 7 ) {
           debug_list.shift();
       }
       debug.innerHTML = debug_list.join( '<br />' );
   }
}


/****   Communication with the server tools   *****/


// makes a string of parameters and their values
// from http://jpspan.sourceforge.net/wiki/doku.php?id=javascript:xmlhttprequest:snippets:post
function buildUrl(varList) {
   var separator = '';
   var url = '';

   if ( typeof encodeURIComponent == 'function' ) {
       for ( name in varList ) {
           url += separator + encodeURIComponent(name)
               + '=' + encodeURIComponent(varList[name]);
           separator = '&';
       }

   } else {
       for ( name in varList ) {
           url += separator + escape(name)
               + '=' + escape(varList[name]);
           separator = '&';
       }
   }
   return url;
}


// Create XMLHttpRequest object
// mostly copied from http://developer.apple.com/internet/webcontent/xmlhttpreq.html

function create_xml_http_request() { 

    var req;
    // branch for native XMLHttpRequest object
    if (window.XMLHttpRequest) {

        try { 
            req = new XMLHttpRequest();
        } catch ( e ) {
            req = false;
        }

    // branch for IE/Windows ActiveX version
    } else if (window.ActiveXObject) {

        try { req = new ActiveXObject("Msxml2.XMLHTTP"); }
        catch (e) {
            try { req = new ActiveXObject("Microsoft.XMLHTTP"); } 
            catch(e) {
                req = false;
            }
        }
    }
    return req;
}


// Send a request 
function send_request( request, process ) {

    name_group['in_progress'] = 1;

    if ( request.l || request.f ) {
        DEBUG( "REQ " 
           + "l: <b>" + request.l 
           + "</b> f: <b>" + request.f 
           + "</b>" );
    } else if ( request.e ) {
        DEBUG( "REQ e: <b>" + request.e + "</b>" );
    } else if ( request.s ) {
        DEBUG( "REQ s: <b>" + request.s + "</b>" );
    }

    // prepare data
    var data = buildUrl( request );
    last_request_data = data;
    
    // check our cache
    if ( cache[data] ) {

        DEBUG( "cached" );
        if ( data == menu_for_request_data 
             && menu_for_group == name_group_prefix ) {
            name_group['in_progress'] = null;
            return;
        }
        process( name_group_prefix, cache[data], request );
        return;
    }
    
 
    var xhr = create_xml_http_request();

    if ( xhr ) {

        // remember the control group we are searching for
        var prefix = name_group_prefix;
        xhr.onreadystatechange = function () {
            handle_req_state_change( xhr, prefix, data, 
                                     process, request );
        }
        xhr.open( "POST", base_url, true );
        xhr.setRequestHeader(
                           'Content-Type',
                           'application/x-www-form-urlencoded; charset=UTF-8'
                           );    
        xhr.send( data );

    } else {
        DEBUG( "can't create XMLHttpRequest" );
    }
}




function handle_req_state_change( req, prefix, reqstring, process, request ) {

    // if state is "complete"
    if ( req.readyState == 4 ) {
        // if status is "OK"
        if ( req.status == 200 ) {

            if ( name ) {
              var data = preprocess_response_doc( req.responseXML.documentElement );
              process( prefix, data, request );
              cache[reqstring] = data;

            } else {
              DEBUG( "no name_group in handle_req_state_change" );
            }

        } else {
            // When there's an internal server error, for instance

            DEBUG("Request problem:\n" 
            + "Status: " + req.status + " -- " + req.statusText);

            name_group.in_progress = false;

        }
    }
}


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


/******   tools for our own bookkeeping   *****/


function make_new_name_group ( Prefix ) {
  return { 
    prefix: Prefix
  };
}


// Identify, which group of controls we are dealing with; set
// name_group and name_group_prefix accordingly.
function set_name_group ( t ) {

  var element_name = (t && t.name) ? t.name : this.name;
  var group_re = /^([a-z]+_\d+_)(family|given|id)$/;
  name_group_prefix = group_re.exec( element_name )[1];
  name_group = name_groups[name_group_prefix];

  if ( menu_for_group 
       && name_group_prefix != menu_for_group ) {
      remove_menu();
  }

  if ( undo_button_for_group 
       && name_group != undo_button_for_group ) {
      remove_undo();
  } 

  if ( name_group['has_undo'] ) {
      make_undo( name_group );
  }

  return true;
}




// id status switching
function set_id_valid( group ) {
    var el = d.getElementsByName( group.prefix+'id' )[0];
    if ( el ) {
        el.className='idvalid';
        el.setAttribute( 'title', "" );
    } else {
        DEBUG( "can't find id element" );
    }
}

function set_id_null( group ) {
    var el = d.getElementsByName( group.prefix+'id' )[0];
    if ( el ) {
        el.className='';
        el.setAttribute( 'title', "" );
    } else {
        DEBUG( "can't find id element" );
    }
    
}

function set_id_invalid( group ) {
    var el = d.getElementsByName( group.prefix+'id' )[0];
    if ( el ) {
        el.className='idinvalid';
        el.setAttribute( 'title', textIdUnknownHint );
    } else {
        DEBUG( "can't find id element" );
    }
}


/* preprocessing returned XML */

function preprocess_response_doc( doc ) {

  var people = new Array;
  var elements = doc.getElementsByTagName( 'person' );
  var i;

  for( i=0; i<elements.length; i++ ) {
      var perel = elements[i];
      var namefull, shortid, given, family, url, homepage;
      namefull = perel.getElementsByTagName( 'namefull'    )[0].firstChild.data;
      shortid  = perel.getElementsByTagName( 'shortid'     )[0].firstChild.data;
      given    = perel.getElementsByTagName( 'givenname'   )[0].firstChild.data;
      family   = perel.getElementsByTagName( 'familyname'  )[0].firstChild.data;
      url      = perel.getElementsByTagName( 'profile_url' )[0].firstChild.data;
      if ( perel.getElementsByTagName( 'homepage'    )[0].firstChild ) {
        homepage = perel.getElementsByTagName( 'homepage'    )[0].firstChild.data;
      } else { homepage = null; }

      people[i] = { 'namefull': namefull,
                    'shortid' : shortid,
                    'given'   : given,
                    'family'  : family,
                    'url'     : url,
                    'homepage': homepage
      };

      
  }
  return people;

}






/**************   INSTALL CHECK HANDLERS     *************/

// Goes through the page's DOM tree and checks for personal
// information input controls.  If there are any, it installs relevant
// handlers to onfocus, onkeyup and onblur events.

// It is executed just once, when the page is completely loaded in the
// browser, via the body element's onload event.  It is installed
// there with help of the addLoadEvent() utility function.

function install_check_handlers() {
    
  if ( ! create_xml_http_request() ) { return false; }
    
  var inputs = document.getElementsByTagName('input');
  var family_re = /^([a-z_\d]+_)family$/;
  var given_re  = /^([a-z_\d]+_)given$/;
  var id_re     = /^([a-z_\d]+_)id$/;

  for ( var i=0; i < inputs.length; i++ ) {
    var el = inputs[i];
    if ( family_re.test( el.name ) ) {
        var prefix = RegExp.$1;
        name_groups[prefix] = make_new_name_group(prefix);

        el.onfocus = family_element_on_focus;
        el.onkeyup = family_element_on_keyup;
        el.onblur  = family_element_on_blur;
    }

    if ( given_re.test( el.name ) ) {
        el.onfocus = given_element_on_focus;
        el.onkeyup = given_element_on_keyup;
        el.onblur  = check_name;
    }

    if ( id_re.test( el.name ) ) {
        el.onfocus = id_element_on_focus;
        el.onkeyup = id_element_on_keyup;
        name_groups[prefix]['idEl'] = el;
    }
  }


  //  debug = d.getElementById("DEBUG"); 

  preload_images();

  return true;
}


/* to run that as soon as the page loads */
addLoadEvent( install_check_handlers );


/* the handlers */

function family_element_on_blur() {
    name_group['in_family'] = 0;
    //    check_name();
}

function family_element_on_focus() {
    set_name_group(this);
    name_group['in_family'] = 1;
    check_name();
}

function family_element_on_keyup() {
    if ( name_group['last_family'] 
         && name_group['last_family'] != this.value ) {
        name_group['ignore'] = null;
        name_group['chosen'] = null;
	clear_undo( name_group );
	remove_undo();
    }
    check_name();
    name_group['last_family'] = this.value;
}


function given_element_on_focus() {
    set_name_group(this);
    check_name();
}

function given_element_on_keyup() {
    if ( name_group['last_given'] 
         && name_group['last_given'] != this.value ) {
        name_group['ignore'] = null;
        name_group['chosen'] = null;
	clear_undo( name_group );
	remove_undo();
    }
    check_name();
    name_group['last_given'] = this.value;
}



function id_element_on_focus() {
    set_name_group(this);
    check_id( this.value );
}

function id_element_on_keyup() {
    if ( name_group['last_id'] 
         && name_group['last_id'] != this.value ) {
        set_id_null( name_group );
        name_group['ignore'] = null;
        name_group['chosen'] = null;
	clear_undo( name_group );
	remove_undo();
    }
    check_id( this.value );
    name_group['last_id'] = this.value;
}



// Get values from the name input fields of the current group and
// return a request array.
function get_user_input_names () {

  var family_control = name_group['famEl'];
  var given_control  = name_group['givEl'];

  // do we still need this?
  if ( ! family_control ) {
      family_control = d.getElementsByName( name_group_prefix
                                            + 'family' )[0];
      given_control  = d.getElementsByName( name_group_prefix
                                            + 'given' )[0];
      //      name_group['famEl'] = family_control;
      //      name_group['givEl'] = given_control;
  }

  var family_name = normalize( family_control.value );
  var given_name  = normalize( given_control.value );


  if ( !family_name && !given_name ) {
      return null;
  }

  if ( name_group.in_family ) {
      family_name = family_name + '*';
  }

  var request = { l: family_name,
                  f: given_name };

  return request;
}


/********     SEARCH BY NAME      **********/

function check_name() {

  if ( !name_group_prefix ) {
      DEBUG( "no name_group_prefix" );
      return false;
  }

  if ( name_group.in_progress ) { 
      name_group.repeat = true;
      DEBUG( "in progress!" );
      return false;
  }

  if ( name_group.ignore ) {
      DEBUG( "ignore!" );
      return false;
  }

  var request = get_user_input_names();
  if ( !request ) {
      return false;
  }


  send_request( request, process_name_search_results );
  return true;
}


// Check shortid or email that the user typed
function check_id( ) {

  if ( !name_group_prefix ) {
      DEBUG( "no name_group_prefix" );
      return false;
  }

  if ( name_group.in_progress ) { 
      name_group.repeat = true;
      DEBUG( "in progress!" );
      return false;
  }

  if ( name_group.ignore ) {
      DEBUG( "ignore!" );
      return false;
  }

  var id_control = d.getElementsByName( name_group_prefix
                                            + 'id' )[0];
  var value = id_control.value;
  //  var value = name_group.idEl.value;
  var request;
  var process;

  value = normalize( value );

  if ( value 
       && name_group['chosen']
       && name_group['chosen'] == value ) {
      DEBUG( "won't search because user have chosen already" );
      return false;
  }

  name_group['last_searched_id'] = value

  if ( is_email( value ) ) {
      request = { e : value };
      process = process_name_search_results;

  } else if ( is_id( value ) ) {
      request = { s : value };
      process = process_id_search_results;

  } else {
      DEBUG( "value is not searchable "+value );
  }

  if ( request ) {
      send_request( request, process );
      return true;
  } 
  
  return false;
}




/* function process_name_search_results */
function process_name_search_results ( prefix, results, request ) {
  var group = name_groups[prefix];

  // Check for a quick user, who might have changed control group while
  // we searched.  That would probably mean it is too late to display
  // the results.  See note above.  
  if ( prefix != name_group_prefix ) {
      group.in_progress = false;
      DEBUG( "user switched control group already" );
      remove_menu();
      return;
  }

  group['in_progress'] = null;

  // Have user done something important while we searched?  Shall we
  // start again?
  if ( group.repeat ) {
      group.repeat = false;

      if ( check_name() ) {
          // if it did search, then it will display results
          return;
      }
      // otherwise we shall go on and display our results
  }

  //  group['ignore'] = 1;

  if ( results.length ) {
    create_menu( results, prefix, textMenuPrompt );

  } else {
    // hide menu if it is present
    remove_menu();
  }

}



/* function process_id_search_results */
function process_id_search_results ( prefix, results, request ) {
  var id     = request["s"];

  var group  = name_groups[prefix];

  if ( !group.repeat ) { 
      if ( results.length ) {
          set_id_valid( group );
      } else {
          set_id_invalid( group );
      }
  }

  // Check for a quick user, who might have changed control group while
  // we searched.  That would probably mean it is too late to display
  // the results.  See note above.  
  if ( prefix != name_group_prefix ) {
      group.in_progress = false;
      DEBUG( "user switched control group already" );
      remove_menu();
      return;
  }

  group['in_progress'] = null;

  // Have user done something important while we searched?  Shall we
  // start again?
  if ( group.repeat ) {
      group.repeat = false;

      if ( check_id() ) {
          // if it did search, then it will display results
          return;
      }
      // otherwise we shall go on and display our results
  }

  //  group['ignore'] = 1;

  var message;

  if ( results.length ) {
      message = make_text( textIdPrompt, id );
  } else {
      message = make_text( textIdUnknown, id );
  }

  create_menu( results, prefix, message );

}






// Present the result of search -- build a menu of options.
function create_menu( data, prefix, prompt ) {

  // hide menu if it is present
  remove_menu();

  var family_input = document.getElementsByName( prefix + 'family')[0];
  var row = family_input.parentNode.parentNode;
  
  var group = name_groups[prefix];
  var el;

  if ( group
       && group.chosen ) {

      DEBUG( "a choice is made already" );
      return true;
  }

  menu_for_group = prefix;
  menu_for_request_data = last_request_data;

  el = d.createElement('tr');
  el.setAttribute( 'id', 'PIDAidMenu' );
  el.setAttribute( 'class', 'pidaidmenu' );
  el.className = 'pidaidmenu';
  el.appendChild( d.createElement('td') );
  el.appendChild( d.createElement('td') );

  var td = el.lastChild;
  td.setAttribute( 'colspan', '4' );
  td.setAttribute( 'colSpan', '4' ); // for IE

  if ( row.nextSibling ) {
    row.parentNode.insertBefore( el, row.nextSibling );
  } else {
    row.parentNode.appendChild( el );
  }
  menu = td;


  if ( data.length ) { 

      var table = '<table class=pidaid>' +
	  '<caption><p>' + prompt + '</p></caption>';
	  
      
      for ( i=0; i < data.length; i++ ) {
	  table = table + make_menu_table_row_text( data[i] );
      }

      table = table + '</table>';

      menu.innerHTML = table;

      var rows = menu.getElementsByTagName( 'tr' );
      for ( i=0; i < rows.length; i++ ) {
	  var r = rows[i];
	  var click = make_menu_table_onclick( data[i] );
	  var links = r.getElementsByTagName( 'A' );
	  var ai;
	  for ( ai = 0; ai < links.length; ai++ ) {
	      var href = links[ai].getAttribute( 'href' );
	      var cl   = links[ai].className;
	      if ( href == '#' 
		   || cl == 'vari' 
		   || cl == 'click' ) {
		  links[ai].onclick = click;
	      }
	  }
      }

  } else {
      el = d.createElement( 'p' );
      el.appendChild( d.createTextNode( prompt ) );
      el.className = 'pidaid';
      menu.appendChild( el );
  }

  group.in_progress = false;
  return true;
}



function remove_menu () {
    var menu = document.getElementById( 'PIDAidMenu' );
    if ( menu ) {
      menu.parentNode.removeChild( menu );
    }
    menu_for_group = null;
    menu_for_request_data = null;
}


function preload_images() {
  var p = new Image( 13, 13 );
  p.src = img_base + 'images/profileinfo.png';
  
  var h = new Image( 12, 12 );
  h.src = img_base + 'images/homepage.png';

  var c = new Image( 15, 15 );
  c.src = img_base + 'images/choose.png';

  var f = new Image( );
  f.src = img_base + 'images/face.gif';

}

// Build HTML DOM tree for a single entry of the menu table.
function make_menu_table_row( person ) {

  var item, td, el, text, img;
  var namefull, shortid, given, family, url, homepage;

  namefull = person['namefull'];
  shortid  = person['shortid' ];
  given    = person['given'   ];
  family   = person['family'  ];
  url      = person['url'     ];
  homepage = person['homepage'];


  var elFamily = d.getElementsByName( name_group_prefix + 'family' )[0];
  var elGiven  = d.getElementsByName( name_group_prefix + 'given' )[0];
  var elId     = d.getElementsByName( name_group_prefix + 'id' )[0];
  var group    = name_groups[name_group_prefix];


  if ( !elFamily ) {
      DEBUG( "didn't find family element for " + name_group_prefix );
  }

  if ( !elGiven ) {
      DEBUG( "didn't find given element for " + name_group_prefix );
  }

  // the choice function
  var onclick = function () {      
      group['chosen'] = shortid;
      group['ignore'] = 1;
      group['in_progress'] = 1;

      elFamily.value = family;
      elGiven.value  = given;
      elId.value     = shortid;

      group['last_id']     = shortid;
      group['last_family'] = family;
      group['last_given']  = given;

      set_id_valid( name_group );
      
      elId.focus();
      remove_menu();
      group['ignore'] = null;
      group['in_progress'] = null;
      DEBUG( "choice: " + shortid );
      return false;
  }

 
  
  item = d.createElement( 'tr' );

  // the name cell
  td   = d.createElement( 'td' );
  td.setAttribute( 'class', 'name' );
  td.className = 'name';  // for IE

  el   = document.createElement( 'a' );
  el.onclick = onclick;
  el.setAttribute( 'href',  '#' );
  el.setAttribute( 'class', 'vari' );
  el.className = 'vari';  // for IE
  el.setAttribute( 'title', textChoosePersonHint );

  text = d.createTextNode( namefull );
  el.appendChild( text );
  td.appendChild( el ); // add a to td
  item.appendChild( td ); 


  // the profile link cell
  td   = d.createElement( 'td' );
  el   = d.createElement( 'a'  );
  el.setAttribute( 'href', url );
  el.setAttribute( 'target', '_blank' );
  el.setAttribute( 'title',  textThisPersonDetailsHint );
  img  = d.createElement( 'img' );
  img.setAttribute( 'src', '/images/profileinfo.png' );
  img.setAttribute( 'width',  '13' );
  img.setAttribute( 'height', '13' );

  el.appendChild( img );
  td.appendChild( el );
  item.appendChild( td );

  // the homepage link cell 
  td   = d.createElement( 'td' );

  if ( homepage ) {
      el   = d.createElement( 'a'  );
      el.setAttribute( 'href', homepage );
      el.setAttribute( 'target', '_blank' );
      el.setAttribute( 'title',  textPersonHomepageHint );
      img  = d.createElement( 'img' );
      img.setAttribute( 'src', '/images/homepage.png' );
      img.setAttribute( 'width',  '12' );
      img.setAttribute( 'height', '12' );

      el.appendChild( img );
      td.appendChild( el );
  }
  item.appendChild( td );


  // the choose! link cell 
  td   = d.createElement( 'td' );
  el   = d.createElement( 'a'  );
  el.setAttribute( 'href', '#' );
  el.setAttribute( 'title',  textChoosePersonHint );
  el.onclick = onclick;
  img  = d.createElement( 'img' );
  img.setAttribute( 'src', '/images/choose.png' );
  img.setAttribute( 'width',  '15' );
  img.setAttribute( 'height', '15' );

  el.appendChild( img );
  td.appendChild( el );
  item.appendChild( td );


  return item;
}


// Build HTML <tr> text for a single entry of the menu table.
function make_menu_table_row_text( person ) {

  var item, td, el, text, img;
  var namefull, shortid, given, family, url, homepage;

  namefull = person['namefull'];
  shortid  = person['shortid' ];
  given    = person['given'   ];
  family   = person['family'  ];
  url      = person['url'     ];
  homepage = person['homepage'];


  var elFamily = d.getElementsByName( name_group_prefix + 'family' )[0];
  var elGiven  = d.getElementsByName( name_group_prefix + 'given' )[0];
  var elId     = d.getElementsByName( name_group_prefix + 'id' )[0];
  var group    = name_groups[name_group_prefix];


  if ( !elFamily ) {
      DEBUG( "didn't find family element for " + name_group_prefix );
  }

  if ( !elGiven ) {
      DEBUG( "didn't find given element for " + name_group_prefix );
  }


  var tdhome = '<TD></TD>';
  if ( homepage ) {
      tdhome = '<TD><A HREF="' + homepage + '" TARGET=_blank TITLE="' 
	  + textPersonHomepageHint + '">' + 
	  '<IMG src="' +img_base+ 'images/homepage.png" width="12" width="12" />' + 
	  '</A></TD>';
  }
 
  
  item = '<TR><TD class="name"><A href="#" class="vari" title="'
      + textChoosePersonHint 
      + '">' + namefull + '</A></TD>' + 
      
      '<TD><A href="' + url + '" target="_blank" title="' 
      + textThisPersonDetailsHint
      + '"><IMG src="' + img_base +
      'images/profileinfo.png" width="13" height="13" /></a></td>' +
      
      tdhome +

      '<TD><A href="#" class="click" title="' + textChoosePersonHint + '">'
      + '<IMG SRC="' + img_base + 'images/choose.png" width="15" height="15" />'
      + '</A></TD></TR>'
      ;

  return item;
}


// build an onclick handler for a person menu item
function make_menu_table_onclick( person ) {

  var item, td, el, text, img;
  var namefull, shortid, given, family, url, homepage;

  namefull = person['namefull'];
  shortid  = person['shortid' ];
  given    = person['given'   ];
  family   = person['family'  ];
  url      = person['url'     ];
  homepage = person['homepage'];


  var elFamily = d.getElementsByName( name_group_prefix + 'family' )[0];
  var elGiven  = d.getElementsByName( name_group_prefix + 'given' )[0];
  var elId     = d.getElementsByName( name_group_prefix + 'id' )[0];
  var group    = name_groups[name_group_prefix];


  if ( !elFamily ) {
      DEBUG( "didn't find family element for " + name_group_prefix );
  }

  if ( !elGiven ) {
      DEBUG( "didn't find given element for " + name_group_prefix );
  }

  // the choice function
  return function () {      
      group['chosen'] = shortid;
      group['ignore'] = 1;
      group['in_progress'] = 1;

      group['has_undo']    = true;
      group['undo_family'] = elFamily.value;
      group['undo_given']  = elGiven.value;
      group['undo_id']     = elId.value;

      elFamily.value = family;
      elGiven.value  = given;
      elId.value     = shortid;

      group['last_id']     = shortid;
      group['last_family'] = family;
      group['last_given']  = given;

      set_id_valid( name_group );

      remove_menu();
      elId.focus();
      group['ignore'] = null;
      group['in_progress'] = null;
      DEBUG( "choice: " + shortid );
      return false;
  };
}


function make_undo( g ) {
    
  undo_button_for_group = g;

  var elFamily = d.getElementsByName( name_group_prefix + 'family' )[0];
  var elGiven  = d.getElementsByName( name_group_prefix + 'given' )[0];
  var elId     = d.getElementsByName( name_group_prefix + 'id' )[0];

  var el;

  if ( !d.getElementById( 'pidaidUndo' ) ) {

      var cell = elId.parentNode;
      el = d.createElement('span');
      el.setAttribute( 'id', 'pidaidUndo' );
      cell.appendChild( el );

      el.innerHTML = "<br><input id='pidaidUndoBut' value='" + textUndoButton 
	  + "' type='button'>";
  }
  
  d.getElementById( 'pidaidUndoBut' ).onclick = function () {
      elFamily.value = g['undo_family'];
      elGiven.value  = g['undo_given' ];
      elId.value     = g['undo_id'    ];

      g['has_undo'   ] = false;
      g['undo_family'] = null;
      g['undo_given' ] = null;
      g['undo_id'    ] = null;

      g['chosen'] = null;
      remove_undo();
  };
    
}


function clear_undo ( g ) {
    g['has_undo'   ] = false;
    g['undo_family'] = null;
    g['undo_given' ] = null;
    g['undo_id'    ] = null;
}

function remove_undo () {
    var cell = d.getElementById( 'pidaidUndo' );
    if ( cell ) {
	cell.parentNode.removeChild( cell );
	undo_button_for_group = null;
    }
}



/* my only friend, the end */
