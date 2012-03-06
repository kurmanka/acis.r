<xsl:stylesheet
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:exsl='http://exslt.org/common'
    xmlns:acis='http://acis.openlib.org'
    xmlns:html='http://www.w3.org/1999/xhtml'
    exclude-result-prefixes='exsl html acis'
    version='1.0'>

  <xsl:import href='main.xsl' />

  <xsl:variable name='parents'>
    <acis:par id='research/main'/>
  </xsl:variable>
  <xsl:variable name='current-screen-id'>research/identified</xsl:variable>

  <!--    v a r i a b l e s    -->
  <xsl:variable name='current'
                select='$contributions/accepted'/>
  <xsl:variable name='config-object-types' 
                select='$contributions/config/types'/> 

  <xsl:template name='table-resources-for-editing'>
    <xsl:param name='list'/>
    <tr class='here'>
      <th width='6%'>delete</th>
      <th class='desc'> item description </th>
    </tr>    
    <xsl:for-each select='$list/list-item[id and title]' xml:space='preserve'>
      <xsl:variable name='sid'
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
          id='row_{$sid}'>        
        <td class='checkbutton'
            width='6%'
            valign='top'>          
            <input type='checkbox'
                   name='remove_{$sid}'
                   id='remove_{$sid}' 
                   value='1' />
            <input type='hidden' 
                   name='id_{$sid}'
                   value='{$id}'/>
            <xsl:variable name='config-this-type' 
                          select='$config-object-types/*[name()=current()/type]'/>
            <xsl:choose xml:space='default'>
              <xsl:when test='count( $config-this-type/roles/list-item ) > 1'>
                <span class='role'
                      title='your role in creation of that work'>
                  <select name='role_{$sid}'
                          id='role_{$sid}'
                          size='1'
                          onchange='javascript:getRef("submitB").value="REMOVE CHECKED ITEMS / SAVE CHANGES"'>
                    <xsl:if test='not( $config-this-type/roles/list-item[text()=$role] )'>
                      <xsl:message>
                        <xsl:text>Role '</xsl:text>
                        <xsl:value-of select='$role'/>
                        <xsl:text>' is not a known role for </xsl:text>
                        <xsl:value-of select='type'/>
                        <xsl:text> type of objects. </xsl:text>
                      </xsl:message>
                      <option value='{$role}'
                              selected='1'>
                        <xsl:value-of select='$role'/>
                      </option>
                    </xsl:if>
                    <xsl:for-each select='$config-this-type/roles/list-item'>
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
              <xsl:otherwise xml:space='default'>            
                <br/>            
                <span class='role'
                      title='your role in creation of that work'>
                  <xsl:text>(</xsl:text>
                  <xsl:value-of select='$role'/>
                  <xsl:text>)</xsl:text>
                </span>            
              </xsl:otherwise>
            </xsl:choose>
        </td>
        <td class='description'>
          <xsl:call-template name='present-resource' xml:space='default'>
            <xsl:with-param name='resource'
                            select='.'/>
            <xsl:with-param name='for'
                            select='concat( "remove_", $sid )' />
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
      </tr>      
    </xsl:for-each>
  </xsl:template>

  <xsl:template name='research-identified'>
    <h1>
      <xsl:text>Research profile: your identifed works</xsl:text>
    </h1>
    <xsl:call-template name='show-status'/>
    <xsl:variable name='current-count' 
                  select='count( $current/list-item )'/>
    <xsl:choose>
      <xsl:when test='$current/list-item'>
        <acis:form screen='@research/identified'
                   xsl:use-attribute-sets='form'>
          <xsl:choose>
            <xsl:when test='$current-count &gt; 1'>
              <p>
                <xsl:text>Here are the </xsl:text>
                <xsl:value-of select='$current-count'/>
                <xsl:text> works, that you claim to have authored: </xsl:text>
              </p>
            </xsl:when>
            <xsl:when test='count( $current/list-item ) = 1'>
              <p>
                <xsl:text>Here is the work, that you claim you have authored: </xsl:text>
              </p>
            </xsl:when>
          </xsl:choose>          
          <table class='resources'>
            <xsl:call-template name='table-resources-for-editing'>
              <xsl:with-param name='list'
                              select='$current'/>
            </xsl:call-template>
          </table>          
          <p>
            <input type='hidden' name='mode'
                   value='edit'/>
            <input type='submit'
                   id='submitB'
                   name='continue'
                   class='important'
                   value='REMOVE CHECKED ITEMS'/>
          </p>
          <acis:phrase ref='research-identified-after-save-changes-button'/>
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
      <xsl:with-param name='title'>your works</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='research-identified'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
