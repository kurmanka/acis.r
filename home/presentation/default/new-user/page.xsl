<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl xml'
  version="1.0"> <!-- new-user/page.xsl that is. defines new-user-page template -->

  <xsl:import href='../page.xsl'/>
  <xsl:import href='../person/page.xsl'/>


  <!-- new user registration header tools -->

  <xsl:template name='new-user-logged-notice'>
    <xsl:if test='string-length( $user-name )'>
      <p class='logged-notice'>
        <xsl:choose>
          <xsl:when test='$request-screen = "index" or not($request-screen)'>
            <a href='{$base-url}/new-user/additional!{$session-id}' class='int' 
               title='continue registering'
            >
              <xsl:text>Registering: </xsl:text> 
              <span class='name'><xsl:value-of select='$user-name'/></span>
            </a>
          </xsl:when>
        </xsl:choose>
      </p>
    </xsl:if>
  </xsl:template>


  <xsl:template name='step-number-x-of-steps'>
    <xsl:param name='x'/>
    <xsl:param name='steps'/>

    <xsl:for-each select="exsl:node-set($steps)/step">
      <span>
        <xsl:if test='@title'>
          <xsl:copy-of select='@title'/>
        </xsl:if>
        <xsl:if test='position() = $x'>
          <xsl:attribute name='class'>current</xsl:attribute>
          <xsl:attribute name='title'>
            <xsl:value-of select='@title'/>; you are here<xsl:text/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test='position() &lt; $x'>
          <xsl:attribute name='class'>past</xsl:attribute>
        </xsl:if>

        <xsl:text>&#xA0;</xsl:text>
        <xsl:value-of select='position()'/>

        <xsl:if test='@label'>
          <xsl:text>&#xA0;</xsl:text>
          <xsl:value-of select='@label'/>
        </xsl:if>

        <xsl:text>&#xA0;</xsl:text>
      </span>
      <xsl:text> </xsl:text>
    </xsl:for-each>
        
  </xsl:template>



  <xsl:variable name='registration-steps'>
    <step title='main personal info' label='main'/>
    <step title='name variations'  label='names'/>
    <step title='and employment'   label='affiliations'/>
    <step title='research profile' label='research'/>
    <step title='sending confirmation email' label='email'/>
    <step title='when confirmed' label='ready'/>
  </xsl:variable>



  <xsl:template name='registration-step-number-x'>
    <xsl:param name='x'/>

    <xsl:text>Registration: &#160;</xsl:text>
    <span class='steps'>
      <xsl:call-template name='step-number-x-of-steps'>
        <xsl:with-param name='x' select='$x'/>
        <xsl:with-param name='steps' select='$registration-steps'/>
      </xsl:call-template>
    </span>
        
  </xsl:template>
  


  <xsl:template name='new-user-profile-menu'>
    <p class='menu'>
      <xsl:choose>
        <xsl:when test='$request-screen = "new-user"'>
          <xsl:call-template name='registration-step-number-x'>
            <xsl:with-param name='x' select='"1"'/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test='$request-screen = "new-user/additional"
                  or $request-screen = "name"'>
          <xsl:call-template name='registration-step-number-x'>
            <xsl:with-param name='x' select='"2"'/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test='starts-with( $request-screen, "affiliations") or
                  $request-screen = "new-institution"'>
          <xsl:call-template name='registration-step-number-x'>
            <xsl:with-param name='x' select='"3"'/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when 
test='starts-with( $request-screen, "research" ) or starts-with($request-screen, "research")'>
          <xsl:call-template name='registration-step-number-x'>
            <xsl:with-param name='x' select='"4"'/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test='$request-screen = "new-user/complete"'>
          <xsl:call-template name='registration-step-number-x'>
            <xsl:with-param name='x' select='"5"'/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test='$request-screen = "confirm"'>
          <xsl:call-template name='registration-step-number-x'>
            <xsl:with-param name='x' select='"6"'/>
          </xsl:call-template>

          <xsl:if test="//success">
            <xsl:text> That's it!</xsl:text>
          </xsl:if>
        </xsl:when>
        
        <xsl:when test='string-length($request-screen)'>
<!-- this could be used to remind the user that he was trying to register at
     all, but difficult to give a reasonable reminder -->
<!--
          <xsl:text>Screen: </xsl:text>
          <xsl:value-of select='$request-screen'/>
-->        </xsl:when>

        <xsl:otherwise>

<!--          
          <xsl:call-template name='link-filter'>
            <xsl:with-param name='content'>
              <xsl:copy-of select='$profile-menu-items'/>
            </xsl:with-param>          
          </xsl:call-template>
-->
        </xsl:otherwise>

      </xsl:choose>
    </p>
  </xsl:template>


  <xsl:template name='continue-button'>
    <input type='submit' name='continue' 
           value=' Continue registration '
           class='important'
           title='if you are ready for the next screen'
           />
  </xsl:template>


  <xsl:template name='new-user-page'>
    <xsl:param name='content'/>
    <xsl:param name='title'/>
    <xsl:param name='navigation'/>

    <xsl:call-template name='page'>
      <xsl:with-param name='into-the-top'>
        <xsl:call-template name='new-user-logged-notice'/>
      </xsl:with-param>
      <xsl:with-param name='navigation'>
        <xsl:call-template name='new-user-profile-menu'/>
        <xsl:copy-of select='$navigation'/>
      </xsl:with-param>
      <xsl:with-param name='title'      select='$title'/>
      <xsl:with-param name='content'    select='$content'/>

    </xsl:call-template>

  </xsl:template>




</xsl:stylesheet>
