<!--   This file is part of the ACIS presentation template-set.   -->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"

  version="1.0">  


  <xsl:import href='index.xsl'/>


  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>adm/events preferences</xsl:with-param>
      
      <xsl:with-param name='content'>

<h1>Events browsing</h1>

<p>Options and parameters for the <a ref='/adm/events/'>adm/events/...</a>
screens.</p>


<acis:form id='pref'>

<script>
function save_preferences () {
  var form   = getRef("pref");
  var elimit = form.elements["eventslimit"].value;
  var slimit = form.elements["sessionslimit"].value;
  var sbox   = form.elements["opensbox"].checked || '0';

  setCookie( "elimit", elimit, 10000, "/adm/events/" );
  setCookie( "slimit", slimit, 10000, "/adm/events/" );
  setCookie( "opensbox", sbox, 10000, "/adm/events/" );

  var showmagic    = form.elements["showmagic"].checked || '0';
  var onlyresearch = form.elements["onlyresearch"].checked || '0';

  setCookie( "showmagic",    showmagic,    10000, "/adm/events/" );
  setCookie( "onlyresearch", onlyresearch, 10000, "/adm/events/" );

  // recent is ... hours
  var recent = form.elements["recentis"].value;
  setCookie( "recentis", recent, 10000, "/adm/events/" );


  alert( "Settings saved\n\n" + "elimit="+elimit 
  + "\n" + "slimit=" + slimit 
  + "\n" + "opensbox=" + sbox 
  + "\n" + "showmagic=" + showmagic
  + "\n" + "onlyresearch=" + onlyresearch
  + "\n" + "recent is " + recent + " hours"
  );


}

function setsli() {
  getRef("pref").elements["sessionslimit"].value = this.value;
  return true;
}
function seteli() {
  getRef("pref").elements["eventslimit"].value = this.value;
  return true;
}

function setris() {
  getRef("pref").elements["recentis"].value = this.value;
  return true;
}

</script>

<acis:script-onload>
  var form   = getRef("pref");
  form.save.title='save preferences in cookies';
  form.save.disabled=false;


  var eli = getRef("pref").elements["eventslimit"].value;
  var sli = getRef("pref").elements["sessionslimit"].value;
  var ris = getRef("pref").elements["recentis"].value;

  var elm, i=0;
  while( elm=form.getElementsByTagName( "input" ).item(i++) ) {
    if ( elm.type &amp;&amp; elm.type=="radio" ) {
 
      if ( elm.name =="slim" ) {
        elm.onchange =setsli;
        elm.onclick  =setsli; // for IE/Win
        if ( elm.value == sli ) {
           elm.checked= true;
        }

      } else if ( elm.name == "elim" ) {
        elm.onchange =seteli;
        elm.onclick  =seteli; // for IE/Win
        if ( elm.value == eli ) {
           elm.checked = true;
        }

      } else if ( elm.name == "reis" ) {
        elm.onchange =setris;
        elm.onclick  =setris; // for IE/Win
        if ( elm.value == ris ) {
           elm.checked = true;
        }
      }

    }
  }

</acis:script-onload>


<style>
td, p, select { vertical-align: baseline; }
select { margin-top: 0; }
td input { margin-bottom: 0; }
</style>

<p><small>This page requires (decent) JavaScript.</small></p>


<fieldset>

<legend> &#160; Preferences &#160; </legend>


<table>
<tr>
<td><p>Maximum atomic events per page: </p></td>
<td>
<input name='eventslimit' id='eventslimit' type='text' size='6' 
       value='{$form-values/eventslimit}'
       /><br/>



<label><input type='radio' name='elim' value='500'/>&#160;500&#160;</label>
 <xsl:text> </xsl:text>

<label><input type='radio' name='elim' value='1000'/>&#160;1,000&#160;</label>
 <xsl:text> </xsl:text>

<!--
<label><input type='radio' name='elim' value='2000'/> 2,000 </label>
 <xsl:text> </xsl:text>
-->

<label><input type='radio' name='elim' value='3000' /> 3,000 </label>
 <xsl:text>&#160;</xsl:text>

<!--
<nobr><label><input type='radio' name='elim' value='5000' /> 5,000 </label></nobr>
 <xsl:text> </xsl:text>

<nobr><label><input type='radio' name='elim' value='10000'/> 10,000</label></nobr>
 <xsl:text> </xsl:text>
-->
<nobr><label><input type='radio' name='elim' value='' checked=''/> no limit</label></nobr>

</td>
</tr>

<tr>
<td><p>Maximum sessions per page:</p></td>
<td>
<input type='text' name='sessionslimit' id='sessionslimit' size='6'
       value='{$form-values/sessionslimit}'
/><br/>


<label><input type='radio' name='slim' value='20' />&#160;20&#160;</label>
 <xsl:text> </xsl:text>
<!-- 
<label><input type='radio' name='slim' value='30' />&#160;30&#160;</label>
 <xsl:text> </xsl:text> -->
<label><input type='radio' name='slim' value='50' />&#160;50&#160;</label>
 <xsl:text> </xsl:text>
<!-- <label><input type='radio' name='slim' value='75'  /> 75  </label>&#160; -->
<label><input type='radio' name='slim' value='100' /> 100 </label>&#160;
<!-- <label><input type='radio' name='slim' value='200' /> 200 </label>&#160; -->
<label><input type='radio' name='slim' value='' 
 checked=''/>&#160;no&#160;limit&#160;</label>

</td>
</tr>

<tr>
<td>Show session boxes open by default?</td>
<td><label><input type='checkbox' name='opensbox' value='true' >
<xsl:if test='$form-values/opensbox-true'>
  <xsl:attribute name='checked'/>
</xsl:if>
</input>
Yes, show them open.</label>

</td>
</tr>


<tr>
<td>Show magic sessions?</td>
<td><label><input type='checkbox' name='showmagic' value='true' >
<xsl:if test='$form-values/showmagic-true'>
  <xsl:attribute name='checked'/>
</xsl:if>
</input>
Yes, I like magic.</label>

</td>
</tr>


<tr>
<td>Show only research-profile related events?</td>
<td><label><input type='checkbox' name='onlyresearch' value='true' >
<xsl:if test='$form-values/onlyresearch-true'>
  <xsl:attribute name='checked'/>
</xsl:if>
</input>
Yes, I check claims.</label>

</td>
</tr>



<tr>
<td align='right'><p><a ref='/adm/events/recent'>Recent</a> is &#160;</p></td>
<td>
<p>
<input name='recentis' id='recentis' type='text' size='2' 
       value='{$form-values/recentis}'
       /> hours<br/>


<label><input type='radio' name='reis' value='4'/>&#160;4&#160;</label>
 <xsl:text> </xsl:text>

<label><input type='radio' name='reis' value='8'/>&#160;8&#160;</label>
 <xsl:text> </xsl:text>

<label><input type='radio' name='reis' value='12'/>&#160;12&#160;</label>
 <xsl:text> </xsl:text>

<label><input type='radio' name='reis' value='24'/>&#160;24&#160;</label>
 <xsl:text> </xsl:text>
</p>

</td>
</tr>


<tr><td></td>
<td>

<input type='button' name='save' value=' SAVE PREFERENCES '
class='important' disabled=''
onclick='javascript:save_preferences();'/>

</td></tr>



</table>

</fieldset>




</acis:form>
       
      </xsl:with-param>

    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>