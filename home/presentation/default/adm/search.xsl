<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"

  version="1.0">  

  <!--   This file is part of the ACIS presentation template set.   -->


  <xsl:import href='index.xsl'/>


  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>adm/search</xsl:with-param>
      
      <xsl:with-param name='content'>

<style>
form h2 { margin-top: 1px; }
form.wide h2 { margin-right: 1em; float: left; }
co { 
 font-family: monospaced, courier;
}

</style>

<h1>Search</h1>

<p><a ref='#instructions'>Instructions.</a></p>

<acis:form class='xxx-wide'>

<h2>for documents</h2>

<table>
<tr>
<td>

<input type='hidden' name='for' value='documents'/>

<label for='by'>by </label>

<select name='by' id='by'>
<option value='creator' selected=''>creator name</option>
<option>id</option>
<option>creators</option>
<option>title</option>
</select>

<xsl:text> </xsl:text>

<label for='key'>key: </label>
<input type='text' id='key' name='key' size='60'/>
<br/>

<!--
<label for='show'>show: </label>
<input type='text' id='show' name='show' value='*' size='60'/>
-->

<xsl:text> </xsl:text>

<label for='limit'>limit: </label>
<input type='text' id='limit' name='limit' value='100' size='5'/>

</td><td valign='top'>

<input type='submit' class='important' name='search' value='SEARCH'/>

</td>
</tr>
</table>

</acis:form>



<acis:form>

<h2>for records</h2>

<table><tr><td>

<input type='hidden' name='for' value='records'/>

<label for='by'>by </label>

<select name='by' id='by'>
  <option value='owner'>login</option>
  <option>shortid</option>
  <option value='namefull'>name</option>
  <option value='namelast'>last name</option>
  <option>id</option>
</select>

<xsl:text> </xsl:text>

<label for='key'>key: </label>
<input type='text' id='key' name='key' size='60'/>
<br/>

<!--
<label for='show'>show: </label>
<input type='text' id='show' name='show' value='*' size='60'/>
-->

<xsl:text> </xsl:text>

<label for='limit'>limit: </label>
<input type='text' id='limit' name='limit' value='100' size='5'/>

</td><td valign='top'>

<input type='submit' class='important' value='SEARCH'/>

</td></tr>
</table>


</acis:form>


<acis:form>


<h2>for users</h2>

<table><tr><td>

<input type='hidden' name='for' value='users'/>

<label for='by'>by </label>

<select name='by' id='by'>
  <option>login</option>
  <option>name</option>
</select>

<xsl:text> </xsl:text>

<label for='key'>key: </label>
<input type='text' id='key' name='key' size='60'/>
<br/>

<!--
<label for='show'>show: </label>
<input type='text' id='show' name='show' value='*' size='60'/>
-->

<xsl:text> </xsl:text>

<label for='limit'>limit: </label>
<input type='text' id='limit' name='limit' value='100' size='5'/>

</td><td>

<input type='submit' class='important' name='search' value='SEARCH'/>

</td></tr>
</table>

</acis:form>


<h2 id='instructions'>Instructions</h2>


<p>You choose what field do you want to search by, enter the search
key and push [SEARCH].  If the key expression includes "<co>%</co>"
sign, I assume that you use Mysql's simple pattern matching syntax
(operator <co>LIKE</co>), in which <co>%</co> means zero or more of
any characters.  If your expression doesn't include percent character,
I assume you want full field value matches (for instance, if you
search by a known email address of a user and you enter the full
address).
</p>

<p>
The search works differently when you <b>search for documents by
title</b>.  If you do not use percent char, I will search by full-text
index, so it will be a word-search.  If you do use the percent char, I
will search by substring/phrase match.
</p>


<p>
Generally, this is a simple search utility and it is not
supposed to provide complete information about all the
documents, personal records and users in the system, just
the most basic info.
</p>



        <xsl:call-template name='adm-menu'/>

       
      </xsl:with-param>

    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>