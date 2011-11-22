<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0"> 
  <xsl:import href='general.xsl'/>
  <!-- this template-specific variables: -->  
  <xsl:template match='/data'>
    <xsl:call-template name='message'>
      <xsl:with-param name='to'>
        <xsl:text>"</xsl:text>
        <xsl:value-of select='$user-name'/>
        <xsl:text>" &lt;</xsl:text>
        <xsl:value-of select='$user-login'/>
        <xsl:text>&gt;</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='subject'>
        <xsl:text>account removed</xsl:text>
      </xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:text>&#10;&#10;&#10;Hello </xsl:text>
        <xsl:value-of select='$user-name'/>
        <xsl:text>.&#10;&#10;&#10;Your account in our system was removed as per your request.&#10;If you think this is a mistake, contact the system administrator to restore it.</xsl:text>
      </xsl:with-param>      
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>

