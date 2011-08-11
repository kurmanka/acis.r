// cardiff

function ar_colors (target_element) {
    // alert(input_element);
    //alert(navigator.userAgent);
    var event = find_event(target_element);
    // find anti_event
    if(event == 'accept') {
        anti_event='refuse';
    }    
    if(event == 'refuse') {
        anti_event='accept';
    }    
    // alert ('anti_event is ' + anti_event);
    tr_element=find_ancestor(target_element,'tr');
    // color the event
    var input_elements=tr_element.getElementsByTagName('input');
    // alert (input_elements.length);
    var td_element;
    for (input_count=0;
         input_count < input_elements.length;
         input_count++) {
        // alert (input_count);
        var my_input_element = input_elements[input_count];
        // alert (my_input_element);
        var type = my_input_element.getAttribute('type');
        var ar = my_input_element.getAttribute('value');
        // alert ('ar is ' + ar);
        if(ar == event && type == 'radio') {
            td_element=find_ancestor(my_input_element,'td');
            control_class( td_element, event, true );
            my_input_element.checked=true;
        }
        if(ar == anti_event && type == 'radio') {
            td_element=find_ancestor(my_input_element,'td');
            control_class( td_element, anti_event, false );
            my_input_element.checked=false;
        }
    }
    control_refuse_all_button(tr_element);
    return true;
    // alert ('gone');
}



// 
// deorative color changes for changed fields
//
function c_colors (target_element,initial_state) {
    var name=target_element.nodeName.toLowerCase();
    //alert(navigator.userAgent);
    // alert('from_td is ' + from_td); 
    // define anti event
    // alert ('start r_colors');       
    var event = find_event(target_element);
    if(event == 'accept') {
        anti_event='refuse';
    }    
    if(event == 'refuse') {
        anti_event='accept';
    }    
    // we don'tneed to do the input, it is done by the td
    if(name == 'input') {
        return true;
    }
    // alert(target_element + ' '  + event);
    // alert ('anti_event is ' + anti_event);
    // color the event
    var input_elements=target_element.getElementsByTagName('input');
    // alert (input_elements.length);
    var clicked=false;
    for (input_count=0;
         input_count < input_elements.length;
         input_count++) {
        //alert (input_count);       
        var my_input_element = input_elements[input_count];
        // alert (my_input_element);
        var type = my_input_element.getAttribute('type');
        var ar = my_input_element.getAttribute('value');
        // alert ('ar is ' + ar);
        if(is_in_class(target_element,'refuse') && (type == 'radio' || type == 'checkbox')) {
            // alert('event 1');
            var td_element=find_ancestor(my_input_element,'td');
            control_class( target_element, 'refuse', false );
            control_class( target_element, 'accept', true );
            if(initial_state == 'refuse') {
                // alert('event one, refuse');
                my_input_element.checked=true;
                hide_role_choice(target_element, initial_state,true);
            }
            else {
                // alert('event one, not refuse');
                my_input_element.checked=true;
                hide_role_choice(target_element, initial_state,false);
            }
            return true;
        }
        else {
            // alert('event 2');
            var td_element=find_ancestor(my_input_element,'td');
            control_class( target_element, 'accept', false );
            control_class( target_element, 'refuse', true );
            if(initial_state == 'accept') {
                //  alert('event two, accetp');
                my_input_element.checked=false;
                hide_role_choice(target_element, initial_state,true);
                return true;
            }
            else {
                // alert('event two, not accept');
                my_input_element.checked=false;
                hide_role_choice(target_element, initial_state,false);
                return true;
            }
        }
    }
    // alert ('gone');
}


function hide_role_choice (target_element,initial_state,crit) { 
    //alert(crit);
    // don't do more if we are on     
    if(initial_state == "refuse") {        
        return true;
    }
    // hide the box for the roles
    var tr_element=find_ancestor(target_element,'tr');
    // role selector is to be the only select element
    var select_elements=tr_element.getElementsByTagName('select');
    // alert (input_elements.length);
    for (select_count=0;
         select_count < select_elements.length;
         select_count++) {
        var my_select_element = select_elements[select_count];
        var span_element=find_ancestor(my_select_element,'span');
        control_class(span_element,'hidden',crit);
    }
    return true;
}


function is_in_class ( target, the_class) {
    var target_element;
    // target may be a string, fetch the object
    if ( typeof target == 'string' ) {
        target_element = getRef( target );
        if(! target_element) {
            alert ('Internal error: undefined element with id ' + target);
            return;
        }
    }
    else {
        target_element=target;
    }
    var class_list;
    var class_string;
    class_string=target_element.getAttribute('class');
    // alert('simple case');
    if ( ! class_string ) {
        return false;
    }
    if ( class_string == the_class ) {
        return true;
    }
    class_list = class_string.split( ' ' );
    for ( var count_class=0; 
          count_class < class_list.length;
          count_class++ ) {
        var my_class = class_list[count_class];
        if ( my_class == the_class ) {
            return true;
        }
    } 
    return false;
}



function find_event (input_element) {
    var event=input_element.getAttribute('value');
    // search for appropriate event, if it is not the value=
    var from_td=false;
    if(! event) {
        from_td=true;
        var input_elements=input_element.getElementsByTagName('input');
        // alert (input_elements.length);
        for (input_count=0;
             input_count < input_elements.length;
             input_count++) {
            // alert (input_count);
            var my_input_element = input_elements[input_count];
            // alert (my_input_element);
            var type=my_input_element.getAttribute('type');
            // there are hidden inputs we must not consider
            if(type == 'radio' || type == 'checkbox') {
                event = my_input_element.getAttribute('value');
                // alert('event is '. event);
            }
            // alert('type is '. type);
        }
        // alert('event is ' + event); 
    }
    return event;
}


//
// find_ancestor of a certain name
// 
function find_ancestor (element, name) {
    // alert (element);
    var my_type= typeof(element);
    // alert (my_type);
    if(my_type == 'object') {
        var my_name=element.nodeName.toLowerCase();
        if(my_name == name) {
            return element;
        }
    }
    else {
        // alert ('not an elemnet');
    }
    // look one level up
    // alert(element);
    element = element.parentNode;
    element = find_ancestor(element,name);
    return element;
}


// control() func
// Ensures that the element identified by id either has
// cla as one of its classes or not, depending on the 
// bool logical value.
function control_class ( target, cla, bool ) {
    var target_element;
    // alert(target);
    // alert(cla);
    // alert(bool);
    if ( typeof target == 'string' ) {
        target_element = getRef( target );
        if(! target_element) {
            alert ('Internal error: undefined element with id ' + target);
            return;
        }
    }
    else {
        target_element=target;
    }
    var class_list;
    var class_string;
    class_string=target_element.getAttribute('class');
    // alert('simple case');
    if ( ! class_string || class_string == cla ) {
        if ( bool ) {
            // alert("set " + cla);
            target_element.setAttribute('class',cla);
        } 
        else {
            target_element.setAttribute('class','');
        }
        return;
    }
    // alert('complicated');
    // complication with the class string  containing several classes. 
    class_list = class_string.split( ' ' );
    var already_there = false;
    var its_index;
    var with_cla    ='';
    var without_cla ='';    
    for ( var i=0; i < class_list.length; i++ ) {
        var my_class = class_list[i];
        // alert('my_class is ' + my_class);
        if ( my_class ) {
            with_cla = with_cla + my_class + " ";
            if ( my_class == cla ) {
                already_there = true;
                its_index = i;
            } 
            else {
                without_cla = without_cla + my_class + " ";
            }
            // alert('without_cla is "' + without_cla +'"');
            // alert('with_cla is "' + with_cla + "'");
        }
    } 
    if ( ! already_there ) {
        with_cla = with_cla + cla;
    }
    if ( already_there ) {
        if ( ! bool ) {
            // alert ("without_cla is "+without_cla);
            target_element.setAttribute('class',without_cla);
            return;
        }        
    } 
    else {
        if ( bool ) {
            // alert('with_cla is "' + with_cla + "'");
            target_element.setAttribute('class',with_cla);
            return;
        }
    }   
    return;
}

//
// clears the form, used on loading
//
function clear_forms () {
    var form_elements=document.getElementsByTagName('form');
    var form_count;
    for (form_count=0;
         form_count < form_elements.length;
         form_count++) {
        var my_form_element = form_elements[form_count];
        my_form_element.reset();
    }
}


function refuse_all_undecided () {
    var input_elements=document.getElementsByTagName('input');
    // alert (input_elements.length);
    var input_count;
    var check_next=1;
    for (input_count=0;
         input_count < input_elements.length;
         input_count++) {
        // alert (input_count);
        var my_input_element = input_elements[input_count];
        // alert (my_input_element);
        // alert(my_input_element.getAttribute('value'));
        is_checked=my_input_element.checked;
        // alert("value is " + value); 
        var my_value=my_input_element.getAttribute('value');        
        // alert("value is " + value); 
        if(is_checked && (my_value == 'accept')) {
            // alert('check_next becomes 0');
            check_next=0;
        }
        else {
            if(my_value == 'accept') {
                // alert('check_next becomes 1');
                check_next=1;
            }
        }
        if((check_next == 1) && (! is_checked) && (my_value == 'refuse')) {
            // alert('check_next is ' + check_next);
            my_input_element.checked=true;
            ar_colors(my_input_element);
            check_next=1;
        }        

    }
    return true;
}


//
// decide if the refuse_all button needs to be shown
// 
function control_refuse_all_button (element) {
    // look for the parent of the button
    var parent_of_button_element=document.getElementById('refuse_all_button');
    if(! parent_of_button_element) {
        return;
    }
    var count_checked=0;
    var count_not_checked=0; 
    // it is assumed that the button element is in the form
    var form_element=find_ancestor(parent_of_button_element,'form');
    var input_elements=form_element.getElementsByTagName('input');
    for (input_count=0;
         input_count < input_elements.length;
         input_count++) {
        var my_input_element=input_elements[input_count];
        var value=my_input_element.getAttribute('value');
        // alert('type is ' + type);
        if(value == 'accept' || value == 'refuse') {
            if(my_input_element.checked) {
                count_checked++;
                // alert("checked found");
            }
            else {
                // alert("not checked found");
                count_not_checked++;
            }
        }
        if(count_not_checked > 2 * count_checked + 1) {
            return;
        }
    }
    if(count_checked==count_not_checked) {
        // alert("hide" + parent_of_button_element);
        control_class(parent_of_button_element, 'hide', true);
    }
}

// pitman prepare implements proposals to accept or refuse depending
// an the relevance
function pitman_prepare (below_me_propose_refuse,above_me_propose_accept) {
    var form_elements=document.getElementsByTagName('form');
    // assumes there is only one form
    var form_element=form_elements[0];
    var tr_elements=form_element.getElementsByTagName('tr');
    // alert (tr_elements.length);
    var tr_count;
    //alert('preparing pitman');
    // the title is supposd to contain the number at the end
    // of the title string. We define the regex here so we don't
    // have to repeat it in the loop
    var find_relevance_regex = new RegExp('0\.[0-9]+$');

  // we start at 4 because the first rows don't have the papers
  for (tr_count=4;
       tr_count < tr_elements.length;
       tr_count++) {
      //alert ('tr_count is ' + tr_count);
      var my_tr_element = tr_elements[tr_count];
      var relevance=find_relevance(my_tr_element,find_relevance_regex);
      //alert('relevance found: ' + relevance);
      if(! relevance || relevance <= below_me_propose_refuse) {
          // second argument just gives opposite choice
          set_choice_in_row(my_tr_element,'refuse','accept');
      }
      else if(relevance >= above_me_propose_accept) {
          // second argument just gives opposite choice
          set_choice_in_row(my_tr_element,'accept','refuse');
      }
      // note, this may leave some rows without any work
      //if(tr_count>5) {
      //    alert('done with tr_count');   
      //    break;
      //}
  }
    return true;
}

// part of pitman project
// we find the relevance. We assume it is in the title
// atttribute in the first td inside tr
function find_relevance (tr_element,find_relevance_regex) {
    var td_elements=tr_element.getElementsByTagName('td');
    if(! td_elements.length) {
        return;
    }
    // we assume the title is in the first <td> in the <tr>
    var td_element_with_title=td_elements[0];
    //alert(td_element_with_title);
    var title=td_element_with_title.getAttribute('title');
    if(! title) {
        return;
    }
    // alert('title is ' + title);
    var relevance = find_relevance_regex.exec(title);
    return relevance;
}

// part of pitman project
// set the choice to do, not dont, where do_it and dont
// can be 'accept' and 'refuse'
function set_choice_in_row(tr_element,do_it,dont) {
    var input_elements=tr_element.getElementsByTagName('input');
    if(! input_elements.length) {
        // alert('no input element');
        return;
    }
    var check_next=1;
    for (input_count=0;
         input_count < input_elements.length;
         input_count++) {
        // alert (input_count);
        var my_input_element = input_elements[input_count];
        // alert (my_input_element);
        // alert(my_input_element.getAttribute('value'));
        var is_checked=my_input_element.checked;
        // alert("value is " + value); 
        var my_value=my_input_element.getAttribute('value');
        // alert("value is " + value); 
        if(is_checked && (my_value == dont)) {
            // alert('check_next becomes 0');
            check_next=0;
        }
        else if(my_value == dont) {
            // alert('check_next becomes 1');
            check_next=1;
        }
        if((check_next == 1) && (! is_checked) && (my_value == do_it)) {
            // alert('check_next is ' + check_next);
            my_input_element.checked=true;
            ar_colors(my_input_element);
            check_next=1;
        }
      }
    // alert('done setting choice ' + do_it + ' input element ' + input_count);
}

