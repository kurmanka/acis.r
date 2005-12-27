<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">

  <xsl:import href='../page-universal.xsl'/>
  <xsl:import href='../forms.xsl'/>


  <xsl:variable name='current-screen-id'>personal-name</xsl:variable>


  <xsl:template name='the-name-details' xml:space='preserve'>

        <h1>Name details</h1>
        
        <xsl:call-template name='show-status'/>
        
        <form xsl:use-attribute-sets='form' action='{$base-url}/name!{$session-id}'>

     <xsl:call-template name='fieldset'><xsl:with-param name='content' xmlns='http://x'>
       <p>
         <label for='full'>Full name, required.  Use your native language.</label>
        <br />
        <input name='full-name' id='full' size='50'/>
       </p>


       <p>
        <label for='fn'>First name, required:</label><br/>
         <input name='first-name' id='fn' size='50'/>
        <br />

        <label for='mn'>Middle name:</label><br />
         <input name='middle-name' id='mn' size='50'/>
        <br />

        <label for='ln'>Last name, required:</label><br />
         <input name='last-name' id='ln' size='50'/>
        <br />

        <label for='ns'>Name suffix, if any:</label>
        <br />
        <input name='name-suffix' id='ns' size='6'/>
       </p>

       <p>
        <label for='nlat'>Name in pure English alphabet letters.  Required if
        your name has at least one non-English character.</label>
        <br />
         <input name='name-latin' id='nlat' size='50'/>
       </p>

       <p id='variations'>

         <label for='nvar'>The variations of your name, one per line.
         We will use them to find your works in our database
         automatically.</label>
       </p>

       <table>
<tr>
<td>
         <textarea name='name-variations' id='nvar' cols='40' rows='12'/>
</td>
<td valign='top'>

&#160;
<input id='suggest' type='button'
        style='display: none;'
onclick='suggest_variations();'
title='based on the first, middle and last names above'
class='significant'
value='Suggest variations' />

<br />
&#160;
<input id='reset_nvar' type='button'
onclick='reset_variations();'
style='display: none; margin-top: 4px;'
class='significant'
title='return variations to the initial value'
value='UNDO' />

<script>

var initial_variations;
var nvar;
var initial_list;
var new_list;

function prepare () {
  new_list = nvar.value.split( /\n\r?|\r\n?/ );
}

// This is for IE5.0, which doesn't understand array.push method:
function ar_push( array, item ) {
  if ( array.push ) {
    array.push( item );
  } else { 
    array[ array.length ] = item;
  }
}


function add_variation ( str ) {
  str = str.replace( /\s{2,}/, " " );
  str = str.replace( /^\s+/, '' );
  str = str.replace( /\s+$/, '' );

  var add = true;
  for ( var i = 0; i &lt; new_list.length; i++ ) {
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
    } else { 
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
     } else { 
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
     for ( var i = 0; i &lt; max; i++ ) {
       ar_push( names, names[i] + ', ' + ns ) ;
     }
   }  

   var t = 0;
   for ( i = 0; i &lt; names.length; i++ ) {
     add_variation( names[i] );
     t++;
   }

   publish_new_list();
}

function reset_variations () {
    nvar.value = initial_variations;
    hide( "reset_nvar" );
}

</script>
<script-onload>
  nvar = getRef( "nvar" );
  if ( nvar &amp;&amp; nvar.value ) {
    initial_variations = nvar.value;
    if ( initial_variations 
         &amp;&amp; initial_variations.split ) {
      initial_list = initial_variations.split( /\n\r?|\r\n?/ );
      show( "suggest" );
    }
  }
</script-onload>

</td>
</tr>
       </table>

      </xsl:with-param></xsl:call-template>

      <xsl:variable name='screen-back' select='$response-data/screen-back/text()'/>
      <xsl:if test='string-length( $screen-back )'>
        <input type='hidden' name='back' value='{$screen-back}' />
      </xsl:if>


      <p><input type='submit' class='important'
             value='SAVE AND RETURN TO MENU' name='continue' 
             ><xsl:if test='$screen-back'
             ><xsl:if test='starts-with( $screen-back, "research" )'
             ><xsl:attribute name='value'>SAVE AND GO BACK TO RESEARCH</xsl:attribute
             ></xsl:if
             ><xsl:if test='$screen-back = "research/autoupdate"'
             ><xsl:attribute name='value'
             >SAVE AND RETURN TO RESEARCH AUTOUPDATE</xsl:attribute
             ></xsl:if
             ></xsl:if
             ></input
      >

      <xsl:if test='not( string-length( $screen-back ) )'>
        <xsl:text>&#160; </xsl:text>
        <input type='submit' class='important' name='gotoresearch'
               value='SAVE AND GO TO RESEARCH' />
      </xsl:if>
      </p>
      
    </form>

    

  </xsl:template>



  <xsl:variable name='to-go-options'>
    <xsl:if test='$session-type = "new-user"'>
      <op><a ref='@affiliations'>affiliations profile</a></op>
    </xsl:if>
    <op><a ref='@research'>research profile</a></op>
    <root/>
  </xsl:variable>



  <!--    t h e   p a g e  -->
  
  <xsl:template match='/data'>

    <xsl:call-template name='appropriate-page'>
      <xsl:with-param name='title'>Name details</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='the-name-details'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

</xsl:stylesheet>
