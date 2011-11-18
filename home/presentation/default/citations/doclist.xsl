<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">
 
  <xsl:import href='general.xsl'/>

  <!-- ToK 2008-04-06: was citations/doclist -->
  <xsl:variable name='current-screen-id'>citations/doclist</xsl:variable>
  <xsl:variable name='list' select='$response-data/doclist'/>
  <xsl:variable name='identified-num' select='number($response-data/identified-number)'/>
  <xsl:variable name='potent-new-num' select='number($response-data/potential-new-number)'/>

  <xsl:variable name='sort'>
    <xsl:choose>
      <xsl:when test='$request-subscreen'>
        <xsl:value-of select='$request-subscreen'/>
      </xsl:when>
      <xsl:otherwise>by-new</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:template name='doclisttable-style'>
    <style>
      td.link span.a,
      td.link a:link,
      td.link a:visited {
         width: 100%; 
         padding: 1ex 2ex;
      } 
      td.link a:hover { background: #f4f4f4; }
      big.title { font-style: italic; }
      tr.secondary th { font-weight: normal; }
      #potential { color: #666; }
    </style>
  </xsl:template>

  <xsl:template name='doclisttable-row'>
        <tr>
          <td class='doctitle'>
            <big class='title'>
              <xsl:choose>
                <xsl:when test='number(new/text())'>
                  <a ref='@citations/potential/{doc/sid}' title='see the new citations'><xsl:value-of select='doc/title'/></a>
                </xsl:when>
                <xsl:when test='number(id/text())'>
                  <a ref='@citations/identified/{doc/sid}' title='see the identified citations'><xsl:value-of select='doc/title'/></a>
                </xsl:when>
                <xsl:when test='number(old/text())'>
                  <a ref='@citations/potential/{doc/sid}?old=y' title='see the old potential citations'><xsl:value-of select='doc/title'/></a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select='doc/title'/>
                </xsl:otherwise>
              </xsl:choose>
            </big>
            <xsl:text> </xsl:text>
            <small><a href='{doc/url-about}'>details</a></small>
          </td>
          <td class='link' valign='top'>
            <xsl:choose> 
              <xsl:when test='number(id/text())'>
                <a ref='@citations/identified/{doc/sid}'><xsl:value-of select='id'/></a>
              </xsl:when>
              <xsl:otherwise>
<!--                <span class='a'><xsl:value-of select='id'/></span> -->
              </xsl:otherwise>
            </xsl:choose>
          </td>
          <td class='link' valign='top' style='xbackground:#{similarity/text()}0000;'
              >
            <xsl:choose>
              <xsl:when test='number(new/text())'>
                <a ref='@citations/potential/{doc/sid}'><xsl:value-of select='new'/></a> 
              </xsl:when>
              <xsl:otherwise>
              </xsl:otherwise>
            </xsl:choose>
          </td>
          <td class='link' valign='top'>
            <xsl:choose>
              <xsl:when test='number(old/text())'>
                <a ref='@citations/potential/{doc/sid}?old=y'><xsl:value-of select='old'/></a> 
              </xsl:when>
              <xsl:otherwise>
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
  </xsl:template>

  <xsl:template name='doclisttable-head'>
      <tr>
        <th rowspan='3' align='left'
            valign='bottom'
            >document title</th>
        <th colspan='3'>citations</th>
      </tr>
      <tr class='secondary'>
        <xsl:choose>
          <xsl:when test='$sort="by-id"'>
            <th rowspan='2' valign='top'>identified<small title='sorting'>&#8595;</small>&#160;</th>
          </xsl:when>
          <xsl:when test='$sort="by-new"'>
            <th rowspan='2' valign='top'><a ref='@citations/doclist/by-id' title='sort by identified'>identified</a>&#160;&#160;</th>
          </xsl:when>
        </xsl:choose>
        <th colspan='2' id='potential'>potential</th>
      </tr>
      <tr class='secondary'>
        <xsl:choose>
          <xsl:when test='$sort="by-id"'>
            <th><a ref='@citations/doclist/by-new' title='sort by new'>new</a>&#160;</th>
          </xsl:when>
          <xsl:when test='$sort="by-new"'>
            <th>new<small title='sorting'>&#8595;</small>&#160;</th>
          </xsl:when>
        </xsl:choose>
        <th>old</th>
      </tr>
  </xsl:template>

  <xsl:template name='doclisttable-overview'>
    <xsl:param name='max' select='count($list/list-item)'/>

    <xsl:call-template name='doclisttable-style'/>
    <table>
      <xsl:call-template name='doclisttable-head'/>
      <xsl:for-each select='$list/list-item[position()&lt;=$max and (number(id) or number(new) or number(old))]'>
        <xsl:call-template name='doclisttable-row'/>
      </xsl:for-each>
    </table>
  </xsl:template>

 
  <xsl:template name='doclisttable'>
    <xsl:param name='max' select='count($list/list-item)'/>
    <xsl:call-template name='doclisttable-style'/>
    <table>
      <xsl:call-template name='doclisttable-head'/>
      <xsl:for-each select='$list/list-item[position()&lt;=$max]'>
        <xsl:call-template name='doclisttable-row'/>
      </xsl:for-each>
    </table>
  </xsl:template>


  <xsl:template name='doclist'>
    <h1>Citations for your documents</h1>
    <xsl:choose>
      <xsl:when test='$list/list-item'>
        
        <p>Overall, you have <xsl:value-of
        select='$identified-num'/> identified
        citation<xsl:if test='$identified-num!=1'>s</xsl:if>
        and <xsl:value-of select='$potent-new-num'/> new
        unique potential citation<xsl:if
        test='$potent-new-num!=1'>s</xsl:if>.</p>

        <xsl:call-template name='doclisttable'/>

      </xsl:when>
      <xsl:otherwise>
        <p>You have no documents in your <a
        ref='@research/identified'>research profile</a>,
        sorry.</p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match='/'>
    <xsl:call-template name='cit-page'>
      <xsl:with-param name='title'>citations for your documents</xsl:with-param>
      <xsl:with-param name='content'>
        <xsl:call-template name='doclist'/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>