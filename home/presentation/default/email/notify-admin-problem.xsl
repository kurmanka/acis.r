<!--   This file is part of the ACIS presentation template-set.   -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">  
  <xsl:import href='general.xsl'/>
  <xsl:variable name='errors-table'
                select='document( "../errors.xml" )' />
  <xsl:template match='/data'
                name='notify-admin'>
    <xsl:call-template name='format-message'>
      <xsl:with-param name='to'>
        <xsl:value-of select='$admin-email'/>
      </xsl:with-param>
      <xsl:with-param name='subject'>
        <xsl:text>internal problem: </xsl:text>
        <xsl:value-of select='$error'/>
      </xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='problem-report'/>
      </xsl:with-param>      
    </xsl:call-template>
  </xsl:template>  
  <xsl:template name='problem-report'>
    <p>
      <xsl:text>&#10;error code: </xsl:text>
      <xsl:value-of select='$error'/>
      <br/>
      <xsl:text>&#10;request for: </xsl:text>
      <xsl:value-of select='$request-screen'/>
      <br/>
      <xsl:text>&#10;session id: </xsl:text>
      <xsl:value-of select='$session-id'/>
      <br/>    
      <xsl:text>&#10;session type: </xsl:text>
      <xsl:value-of select='$session-type'/>
    </p>    
    <p>
      <xsl:text>&#10;user login : </xsl:text>
      <xsl:value-of select='$user-login'/>
      <br/>    
      <xsl:text>&#10;user name _: </xsl:text>
      <xsl:value-of select='$user-name'/>
      <br/>
      <xsl:text>&#10;record id: </xsl:text>
      <xsl:value-of select='$record-id'/>
      <br/>
      <xsl:text>&#10;short-id : </xsl:text>
      <xsl:value-of select='$record-sid'/>
    </p>    
    <xsl:choose>
      <xsl:when test='$errors-table//error[@id=$error]'>
        <p>
          <xsl:copy-of select='$errors-table//error[@id=$error]'/>
        </p>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:template>
</xsl:stylesheet>


