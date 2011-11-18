<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">

  <xsl:import href='page.xsl'/>
  <xsl:import href='../misc/login.xsl'/>

  <xsl:variable name='session-id' /><!-- there's no more this session -->

  <xsl:variable name='form-action'>
    <xsl:value-of select='$base-url'/>
  </xsl:variable>
  
  <xsl:template match='/data'>
    <xsl:choose>

       <!-- shouldn't this instead use "success" ? -->

       <xsl:when test='$any-errors'>

         <xsl:call-template name='new-user-page'>
           <xsl:with-param name='title'>problem</xsl:with-param>
           <xsl:with-param name='content' xml:space='preserve'>

             <h1>Confirmation problem</h1>

             <p>Please check the URL in the confirmation email message.  If you
             have already confirmed then it is OK.  Just try to <a ref='/'
             >log in</a>.</p>

             <p>If it fails and you can't login, please let us know.</p>

           </xsl:with-param>
         </xsl:call-template>

       </xsl:when>
       <xsl:otherwise>

         <xsl:variable name='profile' select='$response-data/saved-profiles/list-item[@pos="0"]'/>

         <xsl:call-template name='new-user-page'>
           <xsl:with-param name='title'>New user registration confirmed</xsl:with-param>
           <xsl:with-param name='content' xml:space='preserve'>

     <h1>Confirmed succesfully</h1>

     <h2>Dear <xsl:value-of select='$user-name'/>,</h2>

     <p>Your account is activated and your profile is now available at:</p>

     <p><a href='{$profile/link}' class='int'><xsl:value-of select='$profile/link'/></a></p>

     <p>Whenever you need to update your profile, you can login into our
     service.  Or you may want to login now to try your account:</p>

     <xsl:call-template name='login-form' xml:space='default'>
       <xsl:with-param name='login' select='$user-login'/>
     </xsl:call-template>

     <acis:phrase ref='confirmed-screen-additional-info'/>

    </xsl:with-param>
   </xsl:call-template>

     </xsl:otherwise>
   </xsl:choose>
     

  </xsl:template>
</xsl:stylesheet>
