<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">

  <xsl:import href='main.xsl'/>
  
  <xsl:variable name='parents'>
    <acis:par id='research/main'/>
  </xsl:variable>

  <xsl:variable name='current-screen-id'>research/auto/status</xsl:variable>



  <xsl:template name='status' xml:space='preserve'>

    <xsl:call-template name='show-status'/>

    <h1 style='text-align: center;'
    >Please wait while we search for your works</h1>

    <p>We now search for your name variations in our database.
    Normally this should take less than a minute.</p>
        
    <p>If search takes too long or if you wish to see what is being
    found, check <a ref='@research/autosuggest' >the automatic
    suggestions page</a>.</p>


  </xsl:template>





  <!--   n o w   t h e   p a g e   t e m p l a t e    -->

  
  <xsl:template match='/data'>

    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>automatic search status</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='status'/>
      </xsl:with-param>
    </xsl:call-template>

  </xsl:template>

    





   
</xsl:stylesheet>

