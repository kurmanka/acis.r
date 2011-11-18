<!--   This file is part of the ACIS presentation template-set.   -->
  
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
  version="1.0">  

  <xsl:import href='../page.xsl'/>

  <xsl:variable name='result' select='$response-data/result'/>
  <xsl:variable name='items' select='$result/data/list-item'/>
  

  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>users search results</xsl:with-param>
      
      <xsl:with-param name='content'>

<h1>Users search</h1>

<p><small>query:</small> &#160;
<xsl:value-of select='$result/query'/>
<br/><small>key:</small> &#160;
<xsl:value-of select='$result/key'/>
</p>

<xsl:if test='$result/problem'>

  <p><big>
  <xsl:for-each select='$result/problem/*'>
    <xsl:value-of select='text()'/>
  </xsl:for-each>
  </big></p>

</xsl:if>

<ol>
  <xsl:for-each select='$items'>
  <li>

    <xsl:value-of select='login'/>:
    
    <span class='name'><xsl:value-of select='name'/></span>
    
    (pass: <code><xsl:value-of select='password'/></code>)
    
    (<xsl:value-of select='userdata_file'/>)

    <xsl:text> </xsl:text>
<!--
    <a ref='/adm/search?show=*&amp;for=records&amp;by=owner&amp;key={login}'>records</a>
-->
<acis:form style='display: inline; padding: 6px;' screen='adm/search' class='narrow'>
  <input type='hidden' name='show' value='*'/>
  <input type='hidden' name='for'  value='records'/>
  <input type='hidden' name='by'   value='owner'/>
  <input type='hidden' name='key'  value='{login}'/>
  <input type='submit' value='records' title="see this user's records"/>
</acis:form>

    </li>
  </xsl:for-each>
</ol>
       
      </xsl:with-param>

    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>