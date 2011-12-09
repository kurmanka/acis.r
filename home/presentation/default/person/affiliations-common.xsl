<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"    
    exclude-result-prefixes="exsl xsl html acis"
    version="1.0">

  <xsl:import href='../page-universal.xsl' />
  <xsl:import href='../forms.xsl'/>

  <!--   u t i l i t y   t e m p l a t e   -->
  <xsl:template name='show-institutions'>
    <xsl:param name='list'/>
    <xsl:param name='mode'/>
    <xsl:param name='full' select='"yes"'/>
    <xsl:for-each select='$list/list-item' xml:space='preserve'>
      <xsl:variable name='alter' xml:space='default'>
        <xsl:if test='(position()+1) mod 2'>
          <xsl:text> alternate</xsl:text>
        </xsl:if>
      </xsl:variable>      
      <acis:form screen='@affiliations'
                 xsl:use-attribute-sets='form' 
                 class='narrow institution{$alter} aff-mode-{$mode}'>        
        <div class='actionButton'
             title='Is that your institution?'>
          <input type='submit' 
                 name='{$mode}'
                 class=''
                 value='{$mode}'/>
          <input type='hidden' 
                 name='id'
                 value='{id}'/>
          <xsl:if test='not(id/text())'>
            <input type='hidden'
                   name='name'
                   value='{name}'/>
          </xsl:if>
        </div>        
        <div class='description'>          
          <span class='title'>
            <xsl:value-of select='name'/>
          </span>
          <ul class='details'>
            <xsl:if test='name-english/text()'>
              <li>
                <xsl:text>English name: </xsl:text>
                <span class='title'>
                  <xsl:value-of select='name-english/text()'/>
                </span>
              </li>
            </xsl:if>
            <xsl:if test='name_en/text()'>
              <li>
                <xsl:text>English name: </xsl:text>
                <span class='title'>
                  <xsl:value-of select='name_en/text()'/>
                </span>
              </li>
            </xsl:if>
            <xsl:if test='location/text()'>
              <li>
                <xsl:text>located in: </xsl:text>
                <xsl:value-of select='location/text()'/>
              </li>
            </xsl:if>
            <xsl:if test='homepage'>
              <li>
                <a href='{homepage}' title='External link'>
                  <xsl:text>website</xsl:text>
                </a>
              </li>
            </xsl:if>
            <xsl:if test='email/text()'>
              <li>
                <xsl:text>email: </xsl:text>
                <xsl:value-of select='email/text()'/>
              </li>
            </xsl:if>
            <xsl:if test='$full = "yes"'>
              <xsl:if test='not(location/text()) and postal/text()'>
                <li>
                  <xsl:text>postal address: </xsl:text>
                  <xsl:value-of select='postal/text()'/>
                </li>
              </xsl:if>
              <xsl:if test='phone/text()'>
                <li>
                  <xsl:text>phone: </xsl:text>
                  <xsl:value-of select='phone/text()'/>
                </li>
              </xsl:if>
              <xsl:if test='fax/text()'>
                <li>
                  <xsl:text>fax: </xsl:text>
                  <xsl:value-of select='fax/text()'/>
                </li>
              </xsl:if>
              <xsl:if test='submitted-by/text()'>
                <li>
                  <xsl:text>submitted by: </xsl:text>
                  <xsl:value-of select='submitted-by/text()'/>
                </li>
              </xsl:if>
            </xsl:if>
            <!-- XXX not all fields show here -->            
          </ul>
        </div>
      </acis:form>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name='submit-invitation'>
    <h2 id='submit'>
      <xsl:text>Cannot find your institution?</xsl:text>
    </h2>    
    <p style='margin-bottom: 2em;'>
      <a ref='@new-institution'>
        <xsl:text>Submit a new institution record</xsl:text>
      </a>
      <xsl:text> to </xsl:text>
      <acis:phrase ref='affiliations-submit-to'/>
    </p>    
  </xsl:template>
  <xsl:variable name='to-go-options'>
    <acis:op>
      <a ref='@affiliations'>
        <xsl:text>back to affiliations</xsl:text>
      </a>
    </acis:op>
    <acis:root/>
  </xsl:variable>
  <xsl:variable name='next-registration-step'>
    <a ref='@research'>
      <xsl:text>next registration step: research</xsl:text>
    </a>
  </xsl:variable>

  <xsl:template name='additional-page-navigation'>
    <xsl:call-template name='link-filter'>
      <xsl:with-param name='content'>        
        <xsl:text>
        </xsl:text>    
        <p class='menu submenu'>
          <span class='head here'>            
            <xsl:text>&#160;</xsl:text>            
            <xsl:choose>
              <xsl:when test='$current-screen-id = "affiliations"'>                
                <b>
                  <xsl:text>Affiliations:</xsl:text>
                </b>                
              </xsl:when>
              <xsl:otherwise>                
                <a ref='@affiliations'>
                  <xsl:text>Affiliations:</xsl:text>
                </a>                
              </xsl:otherwise>
            </xsl:choose>            
            <xsl:text>&#160;</xsl:text>
          </span>          
          <span class='body'>            
            <acis:hl screen='affiliations/search'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@affiliations/search'>
                <xsl:text>search</xsl:text>
              </a>
              <xsl:text>&#160;</xsl:text>
            </acis:hl>            
            <acis:hl screen='new-institution'>
              <xsl:text>&#160;</xsl:text>
              <a ref='@new-institution'> 
                <xsl:text>submit&#160;institution</xsl:text>
              </a>
              <xsl:text>&#160;</xsl:text>
            </acis:hl>          
          </span>          
        </p>
        <xsl:text> 
        </xsl:text>        
      </xsl:with-param>
    </xsl:call-template>    
  </xsl:template>  

</xsl:stylesheet>