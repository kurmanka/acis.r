<xsl:stylesheet 
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:exsl='http://exslt.org/common'
    xmlns:acis='http://acis.openlib.org'
    xmlns:html='http://www.w3.org/1999/xhtml'
    xmlns='http://www.w3.org/1999/xhtml'
    exclude-result-prefixes='exsl xml html acis #default'
    version='1.0'>
  <xsl:template name='all-person-names'>
    <xsl:param name='name-string'/>
    <!-- the separator between occurances -->
    <xsl:param name='separator'/>
    <xsl:choose>
      <xsl:when test='contains($name-string,"&amp;")'>
        <xsl:variable name='person-name'> 
          <xsl:value-of select='normalize-space(substring-before($name-string,"&amp;"))'/>
        </xsl:variable>
        <xsl:variable name='remaining-persons'> 
          <xsl:value-of select='normalize-space(substring-after($name-string,"&amp;"))'/>
        </xsl:variable>
        <xsl:call-template name='person-without-comma'>
          <xsl:with-param name='person-name'>
            <xsl:value-of select='$person-name'/>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:if test='$remaining-persons'>
          <xsl:if test='$separator'>
            <xsl:value-of select='$separator'/>
          </xsl:if>
          <xsl:call-template name='all-person-names'>
            <xsl:with-param name='name-string'>
              <xsl:value-of select='$remaining-persons'/>
            </xsl:with-param>
            <xsl:with-param name='separator'>
              <xsl:value-of select='$separator'/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name='person-without-comma'>
          <xsl:with-param name='person-name'>
            <xsl:value-of select='$name-string'/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- author name without trailing comma -->
  <xsl:template name='person-without-comma'>
    <xsl:param name='person-name'/>
    <xsl:variable name='length'>
      <xsl:value-of select='string-length($person-name)'/>
    </xsl:variable>
    <xsl:variable name='last-letter'>
      <xsl:value-of select='substring($person-name,$length)'/>
    </xsl:variable>
    <xsl:variable name='person-name-without-last-letter'>
      <xsl:value-of select='substring($person-name,1,$length - 1)'/>
    </xsl:variable>
    <xsl:variable name='person-name-without-comma'>
      <xsl:choose>
        <xsl:when test='$last-letter = ","'>              
          <xsl:value-of select='$person-name-without-last-letter'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='$person-name'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- this needs to be defined locally -->
    <xsl:call-template name='what-to-do-with-person-name'>
      <xsl:with-param name='person-name'>
        <xsl:value-of select='$person-name-without-comma'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>

