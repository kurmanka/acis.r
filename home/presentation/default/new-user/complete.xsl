<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">

  <xsl:import href='page.xsl'/>

  <xsl:import href='../person/profile-show.xsl'/>



  <xsl:template match='/data'>
    <xsl:call-template name='new-user-page'>
      <xsl:with-param name='title'>You're almost done</xsl:with-param>
      <xsl:with-param name='content'>
        
        <h1>Confirm</h1>

        <xsl:call-template name='show-status'/>

        <xsl:choose>
          <xsl:when test=' not( $any-errors )'>

            <h2>
              We have just sent you a confirmation email
            </h2>
            
            <p>
              The address we sent it to: 
              <strong>
                <xsl:value-of select='$user-login'/>
              </strong>
            </p>
            
            <p>
              Please check your mailbox and follow the instructions in the
              message you get shortly.  Your registration will not be valid until
              this last step is completed.  If you did not get the message, let us
              know.
            </p>
            
            <!-- 
                 <p><a href='{$response-data/confirmation-url}'>confirm now!</a></p>
            -->
            
            <p>
              Below is all the main information of your profile.
              You might want to review it.
            </p>
            
            <hr/>
            
            <xsl:variable name='person' select='$response-data/record'/>
            <xsl:call-template name='personal-profile' xml:space='default'>
              <xsl:with-param name='person' select='$person'/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <p>
              Your registration will be complete when you confirm it.
            </p>
          </xsl:otherwise>
        </xsl:choose>
       
        
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
