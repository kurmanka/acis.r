<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"    
    xmlns:acis="http://acis.openlib.org"
    exclude-result-prefixes='xsl acis'
    version="1.0">
  
  <xsl:import href='../page-universal.xsl'/>
  <xsl:import href='../forms.xsl'/>

  <xsl:variable name='current-screen-id'>openid-setup</xsl:variable>


  <xsl:template match='/data'>
    <!-- i do not know, if we really need this choice here -->
    <xsl:choose>
      <xsl:when test='$advanced-user'>

        <xsl:call-template name='user-account-page'>
          <xsl:with-param name='title'>login via OpenID</xsl:with-param>
          <xsl:with-param name='content'>
            <xsl:call-template name='openid-notyours'/>
          </xsl:with-param>
        </xsl:call-template>

      </xsl:when>
      <xsl:otherwise>

        <xsl:call-template name='appropriate-page'>
          <xsl:with-param name='title'>login via OpenID</xsl:with-param>
          <xsl:with-param name='content'>
            <xsl:call-template name='openid-notyours'/>
          </xsl:with-param>
        </xsl:call-template>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <xsl:template name='openid-notyours'>
    
    <h1>OpenID login: error</h1>
    
    <xsl:call-template name='show-status'/>
    

    <xsl:if test='$response-data/openid_trust_root'>

    <acis:form action='/openid/setup' xsl:use-attribute-sets='form' name='setup' >
      
      <xsl:call-template name='fieldset'> 
        <xsl:with-param name='content'>
          
          <p>It appears as if you are trying to log in to <xsl:value-of select='$response-data/openid_trust_root'/>
          as <a href='{$response-data/openid_claimed_id}'><xsl:value-of select='$response-data/openid_claimed_id'
          /></a>, but it is not yours.</p>
                    
          <p>Your profile URL and OpenID is: <xsl:value-of select='$response-data/profile-url'/></p>

          <p>You can <a ref='off'>log out</a> and try again, if that was your intention.</p>
          
        </xsl:with-param>
      </xsl:call-template>
      
    </acis:form>
    </xsl:if>
    
  </xsl:template>
  


</xsl:stylesheet>
