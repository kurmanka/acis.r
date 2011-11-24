var initial_variations;
var nvar;
var initial_list;
var new_list;

function prepare () {
    new_list = nvar.value.split( /\n\r?|\r\n?/ );
    if(new_list[0] == '') {
        new_list.shift ;
    }    
}

// This is for IE5.0, which doesn't understand array.push method:
function ar_push( array, item ) {
    if ( array.push ) {
        array.push( item );
    } 
    else { 
        array[ array.length ] = item;
    }
}


function add_variation ( str ) {
    str = str.replace( /\s{2,}/, " " );
    str = str.replace( /^\s+/, '' );
    str = str.replace( /\s+$/, '' );
    
    var add = true;
    for ( var i = 0; i < new_list.length; i++ ) {
        if ( new_list[i] == str ) {
            return;
        }
    }
    
    ar_push( new_list, str );
    //  new_list.push( str );
} 

function publish_new_list () {
    nvar.value = new_list.join( "\n" );
    if ( nvar.value != initial_variations ) {
        nvar.focus();
        show( "reset_nvar" );
    }  
}


function suggest_variations () {
    
    prepare();
    

    var fn = getRef( "fn" ).value;
    var ln = getRef( "ln" ).value;
    var mn = getRef( "mn" ).value;
    
    // name suffix
    var ns = getRef( "ns" ).value;
    
    var names = new Array( );
    
    var fi;
    if ( fn ) {
        if ( fn.length == 1 ) {
            fi = fn + ".";
            fn = '';
        }
        else { 
            fi = fn.charAt(0) + '.';
        }
    }
    
    if ( fn ) {
        ar_push( names, ln + ', ' + fn );
        ar_push( names, fn + ' ' + ln );
    }
    
    if ( fi ) {
        ar_push( names, ln + ', ' + fi );
        ar_push( names, fi + ' ' + ln );
    }
    
    var mi;
    if ( mn ) {
        if ( mn.length == 1 ) {
            mi = mn + ".";
            mn = '';
        }
        else { 
            mi = mn.charAt(0) + '.';
        }
        
        if ( fi ) {
            if ( mn ) 
                ar_push( names, [fn, mn, ln] . join( " " ) );
            if ( mi ) 
                ar_push( names, [fn, mi, ln] . join( " " ) );
        }
        
        ar_push( names, ln + ', ' + fn + ' ' + mn );
        
        if ( mi ) {
            ar_push( names, ln + ', ' + fn + ' ' + mi );
            ar_push( names, fn + ' ' + mi + ' ' + ln );
            
            if ( fi ) {
                ar_push( names, ln + ', ' + fi + ' ' + mi );
                ar_push( names, [ fi, mi, ln ] .join( ' ' ) );
            }
        }
        
    }
    
    if ( ns ) {
        var max = names.length;
        for ( var i = 0; i < max; i++ ) {
            ar_push( names, names[i] + ', ' + ns ) ;
        }
    }  
    
    var t = 0;
    for ( i = 0; i < names.length; i++ ) {
        add_variation( names[i] );
        t++;
    }
    
    publish_new_list();
}

function reset_variations () {
    nvar.value = initial_variations || '';
    hide( "reset_nvar" );
}

