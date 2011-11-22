<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:acis="http://acis.openlib.org"
  xmlns:html="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xml html acis"
  version="1.0">
  
  <xsl:import href='page.xsl'/>
  <xsl:import href='page-universal.xsl'/>
  <xsl:import href='misc/login.xsl'/>
  <xsl:variable name='current-screen-id'>homepage</xsl:variable>
  <xsl:variable name='full-page-title'>
    <xsl:value-of select='$site-name-long'/>
  </xsl:variable>  
  <xsl:template match="/data">
    <xsl:call-template name='page'>
      <xsl:with-param name='into-the-top'>
        <xsl:choose>
          <xsl:when test='$session-type = "new-user"'>
            <xsl:call-template name='new-user-logged-notice'/>
          </xsl:when>
          <xsl:when test='$session-type = "user"'>
            <xsl:call-template name='user-logged-notice'/>
          </xsl:when>
          <xsl:when test='not( $session-type )
                          and //auto-login-possible'>
            <xsl:for-each select='//auto-login-possible'>
              <p class='logged-notice'>
                <a href='{$base-url}/welcome'
                   class='int'
                   title='Enter into your account!'>
                  <xsl:text>Welcome, </xsl:text>
                  <span title='{login/text()}'
                        class='name'>
                    <xsl:value-of select='name' />
                  </span >
                  <xsl:text>!</xsl:text>
                </a>
              </p>
            </xsl:for-each>
          </xsl:when>
        </xsl:choose>
      </xsl:with-param>      
      <xsl:with-param name='content'>        
        <acis:phrase ref='service-intro'/>        
        <acis:phrase ref='news'/>
        <div class="not_in_sorry_site">
          <h2>New registration</h2>        
          <ul>           
            <xsl:if test='$user-name and ($session-type = "new-user")'>    
              <li>
                <a ref='new-user/additional' 
                   title='to step 2' 
                   tabindex='1'>
                  <xsl:text>Continue registration of </xsl:text>
                  <span class='name' >
                    <xsl:value-of select='$user-name' />
                  </span>
                  <xsl:text> (</xsl:text>
                  <xsl:value-of select='$user-login' />
                  <xsl:text>)</xsl:text>
                </a>
              </li>
            </xsl:if>          
            <li>
              <a ref='new-user!'
                 tabindex='1' 
                 title='Takes 6 steps and a working email address'>
                <xsl:text>Register now</xsl:text>
              </a>
            </li>          
          </ul>        
          <h2>
            <xsl:text>Login</xsl:text>
          </h2>        
          <xsl:call-template name='show-status'/>        
          <xsl:variable name='auto-login' select='//auto-login-possible'/>
          <xsl:if test='$auto-login'>          
            <ul>
              <li>
                <a ref='welcome' tabindex='1'>
                  <xsl:text>As </xsl:text>
                  <span class='name' >
                    <xsl:value-of
                        select='$auto-login/name' />
                  </span>
                  <xsl:text> (</xsl:text>
                  <xsl:value-of select='$auto-login/login' />
                  <xsl:text>) </xsl:text>
                </a>
              </li>
            </ul>          
            <p>
              <xsl:text>... Or enter as another user:</xsl:text>
            </p>
          </xsl:if>        
          <xsl:if test='$user-name and ($session-type = "user")'>          
            <ul>
              <li>
                <a ref='welcome' title='to main menu' >
                  <xsl:text>Already logged-in as </xsl:text>
                  <span class='name' >
                  <xsl:value-of select='$user-name' /></span>
                  <xsl:text> (</xsl:text>
                  <xsl:value-of select='$user-login' />
                  <xsl:text>)</xsl:text>
                </a>
              </li>
            </ul>
          </xsl:if>              
          <xsl:call-template name='login-form'
                             xml:space='default'>
            <xsl:with-param name='no-auto-login-focus'
                            select='"1"'/>
          </xsl:call-template>
        </div>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>  
</xsl:stylesheet>

