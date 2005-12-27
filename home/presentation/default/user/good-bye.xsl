<xsl:stylesheet
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:exsl="http://exslt.org/common"
 exclude-result-prefixes='exsl'
 version="1.0">
  
  <xsl:import href='../page.xsl'/>
  <xsl:import href='../forms.xsl'/>
  <xsl:import href='../misc/login.xsl'/>

  <xsl:variable name='session-id' /><!-- there's no more this session -->

  <xsl:variable name='form-action'>
    <xsl:value-of select='$base-url'/>
  </xsl:variable>

  <xsl:template match='/data'>
    <xsl:call-template name='page'>
      <xsl:with-param name='title'>thanks</xsl:with-param>
      
      <xsl:with-param name='content'>

        <h1>Good bye</h1>
        
        <xsl:call-template name='show-status'/>

        <xsl:choose>
          <xsl:when test='$success'>
        
            <p>Your changes saved and session closed.</p>
        
            <xsl:choose>
        
              <xsl:when test='$record-about-owner and 
                        count( $response-data/saved-profiles/list-item ) = 1'>
                <p>Check your <a class='int'
                href='{$response-data/permalink}'>updated profile
                page</a>.</p>
              </xsl:when>
              
              <xsl:otherwise>
                <p>Written (updated) profile pages:</p>
                
                <ul>
                  <xsl:for-each select='$response-data/saved-profiles/list-item'>
                    <li>
                      <a href='{link/text()}' class='int' 
                      ><xsl:value-of select='name'/></a>
                    </li>
                  </xsl:for-each>
                </ul>
                
              </xsl:otherwise>
            </xsl:choose>
    
          </xsl:when>
          <xsl:otherwise>
            
            <p>You changed nothing, so we had nothing to save this time.</p>        
            
          </xsl:otherwise>
        </xsl:choose>


        <p>You may login again, if you wish:</p>

        <xsl:call-template name='login-form'>
          <xsl:with-param name='login' select='$user-login'/>
        </xsl:call-template>
        


        
      </xsl:with-param>
    </xsl:call-template>
    
  </xsl:template>
  
  
</xsl:stylesheet>
