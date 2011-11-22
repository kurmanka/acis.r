<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
  version="1.0">
  
  <xsl:import href='page.xsl'/>
  <xsl:import href='profile-show.xsl'/>

  <xsl:variable name='session-type'>none</xsl:variable>

  <xsl:variable name='profile-owner' select='//profile-owner'/>
  <xsl:variable name='owner-email'   select='$profile-owner/login'/>
  <xsl:variable name='owner-name'   select='$profile-owner/name' />

  <xsl:template match='/data'>
    
    <xsl:variable name='person' select='$response-data/record'/>
    
    <xsl:call-template name='page'>
      <xsl:with-param name='title'
        ><xsl:value-of select='$person/name/full'/></xsl:with-param>
      <xsl:with-param name='content' xml:space='preserve'>
        
        <xsl:call-template name='personal-profile' xml:space='default'>
          <xsl:with-param name='person' select='$person'/>
        </xsl:call-template>

        <div class='metadata'>

          <xsl:if test='not( $person/about-owner/text()="yes" )'>
            <address>The profile is maintained by <a
            href='mailto:{$owner-email}' title='email address' ><span
            class='name' ><xsl:value-of select='$owner-name' /></span
            ></a >.
            <!-- If you are <span class='name' ><xsl:value-of
            select='$owner-name' /></span >, <a href='{$base-url}'
            class='int' >login</a > to update the record.
            -->
            </address>
          </xsl:if>
          
          <p class='permanent'>Permanent link: 
          <a href='{$response-data/permalink}' class='permanent'>
            <xsl:value-of select='$response-data/permalink/text()'/>
          </a></p>
          
        </div>
        
      </xsl:with-param>

    </xsl:call-template> <!-- /page -->
    
  </xsl:template>
  
</xsl:stylesheet>

