<xsl:stylesheet
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:exsl='http://exslt.org/common'
    xmlns:acis='http://acis.openlib.org'
    xmlns:html='http://www.w3.org/1999/xhtml'    
    exclude-result-prefixes='exsl xml html acis'
    version='1.0'>

  <!-- part of cardiff -->
  <xsl:import href='main.xsl' />
  <xsl:import href='../../widgets.xsl' />
  <xsl:import href='research_common.xsl' />

  <!-- what perl script needs to be called -->
  <xsl:variable name='the-screen'>accepted</xsl:variable>
  <xsl:variable name='parents'>
    <acis:par id='research/main'/>
  </xsl:variable>
  <xsl:variable name='items-count' 
                select='count( $current/list-item )'/>
  <xsl:variable name='this-chunk-size' select='$chunk-size'/>
  <xsl:variable name='more-to-follow' 
                select='$items-count &gt; $chunk-size'/>
  <xsl:variable name='more-to-follow-count' 
                select='$items-count - $chunk-size'/>
  <xsl:variable name='additional-head-stuff'>    
    <script type='text/javascript'
            src='{$base-url}/script/research.js'>
    </script>
  </xsl:variable>
  <xsl:variable name='current-screen-id'>research/accepted</xsl:variable>
  <!--    v a r i a b l e s    -->
  <xsl:variable name='current'
                select='$contributions/accepted'/>
  <xsl:variable name='config-object-types' 
                select='$contributions/config/types'/> 

  <xsl:template name='table-resources-for-editing'>
    <xsl:param name='list'/>
    <tr class='here'>
      <xsl:copy-of select='$item-description-header'/>
      <th style='width: 10em'>your role</th>
      <xsl:copy-of select='$by-you-header'/>
    </tr>    
    <xsl:for-each select='$list/list-item[id and title]'>
      <xsl:variable name='wid'
                    select='generate-id(.)'/>
      <xsl:variable name='dsid'
                    select='sid/text()'/>
      <xsl:variable name='id'
                    select='id'/>
      <xsl:variable name='role'
                    select='role/text()'/>
      <xsl:variable name='alternate'>
      <xsl:if test='position() mod 2'>
        <xsl:text> alternate</xsl:text>
      </xsl:if>
      </xsl:variable>
      <tr class='resource{$alternate}'
          id='row_{$wid}'>        
        <td class='description'>
          <xsl:if test='relevance'>
            <xsl:attribute name='title'>
              <xsl:text>computed probability that this is yours: </xsl:text>
              <xsl:value-of select='relevance'/>
            </xsl:attribute>
          </xsl:if>
          <!-- there was an xml:space='default' on the next element -->
          <xsl:call-template name='present-resource'>
            <xsl:with-param name='resource'
                            select='.'/>
            <!-- id= should the from= for the label element points to -->
            <xsl:with-param name='for'
                            select='concat( "refuse_", $wid )' />
          </xsl:call-template>          
          <xsl:variable name='cidentified'
                        select='$citations/identified'/>
          <xsl:variable name='cpotential'
                        select='$citations/potential'/>
          <xsl:if test='$dsid and $citations//*[name()=$dsid]'>
            <br/>
            <small>
              <xsl:text>citations: </xsl:text>
              <xsl:if test='$cidentified/*[name()=$dsid]'>
                <a ref='@citations/identified/{$dsid}' >
                  <xsl:value-of select='$cidentified/*[name()=$dsid]/text()' />
                  <xsl:text> identified </xsl:text>
                </a >
              </xsl:if>              
              <xsl:if test='count($citations/*/*[name()=$dsid])&gt;1'>
                <xsl:text>|</xsl:text>
              </xsl:if>               
              <xsl:if test='$cpotential/*[name()=$dsid]'>
                <a ref='@citations/potential/{$dsid}'>
                  <xsl:value-of select='$cpotential/*[name()=$dsid]/text()'/>
                  <xsl:text> potential </xsl:text>
                </a>
              </xsl:if>              
            </small>
          </xsl:if>
        </td>
        <td class='checkbutton'
            style='width: 6%'
            valign='top'>          
          <input type='hidden'
                 name='id_{$wid}'
                 value='{$id}'/>
          <xsl:variable name='config-this-type' 
                        select='$config-object-types/*[name()=current()/type]'/>
          <xsl:choose>
            <xsl:when test='count( $config-this-type/roles/list-item ) > 1'>
              <span class='role'                   
                    title='your role in creation of that work'>
                <select name='role_{$wid}'
                        id='role_{$wid}'
                        size='1'>
                  <!-- formerly here onchange='javascript:getRef("submitB").value="REMOVE CHECKED ITEMS / SAVE CHANGES"'> -->
                  <xsl:if test='not( $config-this-type/roles/list-item[text()=$role] )'>
                    <xsl:message>
                      <xsl:text>Role '</xsl:text>
                      <xsl:value-of select='$role'/>
                      <xsl:text>' is not a known role for </xsl:text>
                      <xsl:value-of select='type'/>
                      <xsl:text> type of objects. </xsl:text>
                    </xsl:message>
                    <option value='{$role}'
                            selected='selected'>
                      <xsl:value-of select='$role'/>
                    </option>
                  </xsl:if>
                  <xsl:for-each select='$config-this-type/roles/list-item'>
                    <!-- fixme: the label attribute causes validation errors but has to -->
                    <!-- at this time because otherwise the javascript appears not to operate -->
                    <option label='{text()}'
                            value='{text()}'>
                      <xsl:if test='text() = $role'>
                        <xsl:attribute name='selected'>selected</xsl:attribute>
                      </xsl:if>
                      <xsl:value-of select='text()'/>
                      <!-- XXX: I18N should be replaced with presenter-specific labels -->
                    </option>
                  </xsl:for-each>
                </select>
              </span>
            </xsl:when>
            <xsl:when test='role/text() = $default-role'/>
            <!-- there was an xml:space='default' on the next elemnet -->
            <xsl:otherwise>            
              <span class='role'
                    title='your role in creation of that work'>
                <xsl:text>(</xsl:text>
                <xsl:value-of select='$role'/>
                <xsl:text>)</xsl:text>
              </span>            
            </xsl:otherwise>
          </xsl:choose>
        </td>
        <td class='checkbutton smallwidth accept'
            valign='top'
            onclick='c_colors(this,"accept")'>
          <!-- there decision in the item -->
          <input type='checkbox' 
                 id='refuse_{$wid}' 
                 value='refuse'
                 checked='checked'
                 onclick='c_colors(this,"accept")'>
            <xsl:attribute name='name'>
              <xsl:text>ar_</xsl:text>
              <xsl:value-of select='$wid'/>
            </xsl:attribute>
          </input>
          <!-- document short_id -->
          <input type='hidden' 
                 name='handle_{$wid}' 
                 value='{id}'/>
          <!-- role with the document -->
          <xsl:if test='role'>
            <input type='hidden' 
                   name='role_{$wid}' 
                   value='{role}'/>
            <xsl:if test='role/text() != $default-role'>
              <br/>
              <xsl:text>(</xsl:text>
              <xsl:value-of select='role'/>
              <xsl:text>)</xsl:text>
            </xsl:if>
          </xsl:if>
        </td>
      </tr>      
    </xsl:for-each>
  </xsl:template>
  <xsl:template name='research-accepted'>
    <h1>
      <xsl:text>Research profile: your accepted items.</xsl:text>
    </h1>
    <xsl:call-template name='show-status'/>
    <xsl:variable name='items-count' 
                  select='count( $current/list-item )'/>
    <xsl:choose>
      <xsl:when test='$current/list-item'>
        <xsl:call-template name='tabset'>
          <xsl:with-param name='id' select='"tabs"'/>
          <xsl:with-param name='tabs'>
            <xsl:copy-of select='$the-restricted-tabs'/>
          </xsl:with-param>
        </xsl:call-template>
        <acis:form class='refused' 
                   screen='@research/accepted'
                   xsl:use-attribute-sets='form'>
          <table width='100%'>
            <tr>
              <td>
                <xsl:text>Here </xsl:text>        
                <xsl:choose>
                  <xsl:when test='$items-count &gt; 1'>
                    <xsl:text>are the </xsl:text>
                    <xsl:value-of select='$items-count'/>
                    <xsl:text> items that you have </xsl:text>
                    <span class='accept'>
                      <xsl:text>accepted</xsl:text>
                    </span>
                    <xsl:text> so far.</xsl:text>
                  </xsl:when>
                  <xsl:when test='$items-count = 1'>
                    <xsl:text>is the single item that you have </xsl:text>
                    <span class='accept'>
                      <xsl:text>accepted</xsl:text>
                    </span>
                    <xsl:text> so far.</xsl:text>
                  </xsl:when>
                </xsl:choose>
                <xsl:text> You can tell us what role you had in that item.</xsl:text>
                <xsl:text> If you find an item that you have accepted by mistake, you can </xsl:text>
                <span class='refuse'>
                  <xsl:text>refuse</xsl:text>
                </span>
                <xsl:text> it. </xsl:text>
              </td>
              <td>
                <xsl:copy-of select='$save-and-continue-input'/>
              </td>
            </tr>
          </table>
          <table class='resources'>
            <xsl:call-template name='table-resources-for-editing'>
              <xsl:with-param name='list'
                              select='$current'/>
            </xsl:call-template>
          </table>          
          <table width='100%'>
            <tr>
              <td align='right'>
                <xsl:copy-of select='$save-and-exit-input'/>
              </td>
              <td align='right'>
                <xsl:copy-of select='$save-and-continue-input'/>
              </td>
            </tr>
          </table>     
          <acis:phrase ref='research-accepted-after-save-changes-button'/>
        </acis:form>
      </xsl:when>
      <xsl:otherwise>
        <p>
          <xsl:text>At this moment, there are no works in your research profile.</xsl:text>
        </p>
      </xsl:otherwise>  
    </xsl:choose>
  </xsl:template>
  <!--   n o w   t h e   p a g e   t e m p l a t e    -->
  <xsl:template match='/data'>
    <xsl:call-template name='research-page'>
      <xsl:with-param name='title'>your accepted works</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='research-accepted'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>