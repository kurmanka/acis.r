<!--   This file is part of the ACIS presentation template-set.   -->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">  


  <xsl:import href='general.xsl'/>
  <xsl:variable name='errors-table' select='document( "../errors.xml" )' />


  <xsl:template match='/data' name='notify-admin'>
    <xsl:call-template name='format-message'>
      <xsl:with-param name='to'><xsl:value-of select='$admin-email'/></xsl:with-param>
      <xsl:with-param name='subject'>internal problem: <xsl:value-of
      select='$error'/></xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='problem-report'/>
      </xsl:with-param>      
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template name='problem-report'>

    <p>error code : <xsl:value-of select='$error'/><br/>
    request for: <xsl:value-of select='$request-screen'/><br/>
    session id : <xsl:value-of select='$session-id'/><br />
    session typ: <xsl:value-of select='$session-type'/></p>
    
    <p>user login : <xsl:value-of select='$user-login'/><br/>
    user name _: <xsl:value-of select='$user-name'/><br/>
    record id: <xsl:value-of select='$record-id'/><br/>
    short-id : <xsl:value-of select='$record-sid'/></p>

    <xsl:choose>
      <xsl:when test='$errors-table//error[@id=$error]'>
        <p><xsl:copy-of select='$errors-table//error[@id=$error]'/></p>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  
</xsl:stylesheet>


