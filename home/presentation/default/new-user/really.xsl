<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='page.xsl'/>
  <xsl:import href='../forms.xsl'/>

  <xsl:template name='cancel-button'>
    <input type='submit' name='cancel' 
           value=' Log into my existing account '
           class='important'
           title='registration will be lost'/>
  </xsl:template>

  
  <xsl:template match='/data'>
    <xsl:call-template name='new-user-page'>
      <xsl:with-param name='title'>please check</xsl:with-param>
      <xsl:with-param name='content'>

        <h1>Somebody registered with a similar name</h1>
        
        <xsl:call-template name='show-status'/>
        
        
        
        <p>There are some users with a similar name in our service:</p>

        <ul>
        <xsl:for-each select='//similar-name-profiles/list-item'>
          <li><a href='{url}'><xsl:value-of select='name'/></a></li>
        </xsl:for-each>
        </ul>


        <acis:form xsl:use-attribute-sets='form' name='theform'>

        <p>
        Is one of the above accounts yours? Have you registered here
        before?  Please do not create a duplicate account for you. Rather,
        log into your existing account and change the email address there.
        </p>


        <p>
          <xsl:call-template name='continue-button'/>
          &#160;
          <xsl:call-template name='cancel-button'/>
        </p>

        </acis:form>          
        
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>
