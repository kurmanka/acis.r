<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">

  <xsl:import href='index.xsl'/>
  
  
  <xsl:template match='/'>

    <xsl:variable name='id' select='$form-input/id'/>

    <xsl:call-template name='page'>
      <xsl:with-param name='title'>action on a session</xsl:with-param>
      
      <xsl:with-param name='content'>
        
        <p><big>session <xsl:value-of select='$id'/> 
        <xsl:choose>
          <xsl:when test='$success'>
            deleted
          </xsl:when>
          <xsl:otherwise>
            not deleted
          </xsl:otherwise>
        </xsl:choose>
        </big></p>
        


        <xsl:call-template name='adm-menu'/>


      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>

