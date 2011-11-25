<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0"> 
 
  <xsl:import href='page.xsl'/>
  <xsl:import href='user/page.xsl'/>
  <xsl:import href='new-user/page.xsl'/>
  <xsl:import href='person/page.xsl'/>
 
  <xsl:template name='appropriate-page'>
    <xsl:param name='title'/>
    <xsl:param name='navigation'/>
    <xsl:param name='content'/>

    <xsl:choose>
      <xsl:when test='$session-type ="new-user"'>
        <xsl:call-template name='new-user-page'>
          <xsl:with-param name='title'   select='$title'/>
          <xsl:with-param name='navigation'>
            <xsl:copy-of select='$navigation'/>
          </xsl:with-param>
          <xsl:with-param name='content'>
            <xsl:copy-of select='$content'/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test='$session-type ="user"'>
        <xsl:call-template name='user-page'>
          <xsl:with-param name='title'   select='$title'/>
          <xsl:with-param name='navigation'>
            <xsl:copy-of select='$navigation'/>
          </xsl:with-param>
          <xsl:with-param name='content'>
            <xsl:copy-of select='$content'/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test='$session-type ="admin-user"'>
        <xsl:call-template name='user-page'>
          <xsl:with-param name='title'   select='$title'/>
          <xsl:with-param name='navigation'>
            <xsl:copy-of select='$navigation'/>
          </xsl:with-param>
          <xsl:with-param name='content'>
            <xsl:copy-of select='$content'/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test='not( $session-type )'>
        <xsl:call-template name='page'>
          <xsl:with-param name='title' select='$title'/>
          <xsl:with-param name='navigation'>
            <xsl:copy-of select='$navigation'/>
          </xsl:with-param>
          <xsl:with-param name='content'>
            <xsl:copy-of select='$content'/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

    </xsl:choose>

  </xsl:template>


  <xsl:template name='appropriate-page-soft'>
    <xsl:param name='title'/>
    <xsl:param name='content'/>
    <xsl:param name='navigation'/>

    <xsl:choose>
      <xsl:when test='$session-type ="new-user"'>
        <xsl:call-template name='new-user-page'>
          <xsl:with-param name='title'   select='$title'/>
          <xsl:with-param name='content' select='$content'/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test='$session-type ="user" or $session-type="admin-user"'>
        <xsl:call-template name='user-account-page'>
          <xsl:with-param name='title'   select='$title'/>
          <xsl:with-param name='content' select='$content'/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test='not( $session-type )'>
        <xsl:call-template name='page'>
          <xsl:with-param name='into-the-top'>
            <xsl:choose>
              <xsl:when test='//auto-login-possible'>
                <xsl:for-each select='//auto-login-possible'>
                  <p class='logged-notice'>
                    <a href='{$base-url}/welcome'  class='int' title='Enter into your account!'>
                     Welcome, <span title='{login}' class='name'>
                     <xsl:value-of select='name' />
                    </span >!</a>
                  </p>
                </xsl:for-each>

              </xsl:when>
              <xsl:otherwise>

              </xsl:otherwise>
            </xsl:choose>
            <div class='menu'><span></span></div>
          </xsl:with-param>


          <xsl:with-param name='title'      select='$title'/>
          <xsl:with-param name='navigation' select='$navigation'/>
          <xsl:with-param name='content'    select='$content'/>
        </xsl:call-template>
      </xsl:when>

    </xsl:choose>

  </xsl:template>



  <!--  Epilog: Where to go next? menu after the main page's content. -->
  

  <xsl:variable name='to-go-options'/>

  <xsl:variable name='to-go-options-processed'>
    <xsl:if test='$to-go-options'>
      <xsl:apply-templates select='exsl:node-set( $to-go-options )' mode='to-go-op'/>      
    </xsl:if>
  </xsl:variable>

  <xsl:variable name='next-registration-step'/>

  <xsl:template match='acis:root' mode='to-go-op'>
    <xsl:choose>
      <xsl:when test='$session-type = "user"'>
        <acis:op><a ref='@menu'>profile main menu</a></acis:op>
      </xsl:when>
      <xsl:when test='$session-type = "new-user"'>
        <xsl:if test='$next-registration-step'>
          <acis:op><xsl:copy-of select='$next-registration-step'/></acis:op>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match='*' mode='to-go-op'>
    <xsl:copy-of select='.'/>
  </xsl:template>



  <xsl:template name='content-bottom-navigation'>

    <xsl:if test='$to-go-options'>

      <div class='epilog' id='where-to-go'>
        <h2>Where do you want to go now?</h2>

        <ul>
          <xsl:for-each select='exsl:node-set( $to-go-options-processed )/acis:op'>
            <li><xsl:copy-of select="*|text()"/></li>
          </xsl:for-each>
        </ul>
         
      </div>
    </xsl:if>
  </xsl:template>





</xsl:stylesheet>