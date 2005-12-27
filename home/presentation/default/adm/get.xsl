<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:date="http://exslt.org/dates-and-times"
  exclude-result-prefixes='exsl'
  version="1.0">  

  <!--   This file is part of the ACIS presentation template set.   -->


  <xsl:import href='index.xsl'/>


<xsl:template name='menu'>

<p>
<xsl:choose>
<xsl:when test='$dot/record'
><span class='here'>&#160;the&#160;record&#160;</span>
</xsl:when>
<xsl:otherwise>
<span>&#160;<a ref='/adm/get/{$form-input/col}/{$form-input/id}/rec'
>the record</a>&#160;</span>
</xsl:otherwise>
</xsl:choose>
| 
<xsl:choose>
<xsl:when test='$dot/history'
><span class='here'>&#160;the&#160;history&#160;</span>
</xsl:when>
<xsl:otherwise>
<span>&#160;<a ref='/adm/get/{$form-input/col}/{$form-input/id}'
>the history</a>&#160;</span>
</xsl:otherwise>
</xsl:choose>
</p>

</xsl:template>

  <xsl:template match='/data'>
    <xsl:call-template name='page'>

      <xsl:with-param name='title'>adm/get</xsl:with-param>
      
      <xsl:with-param name='content'>

        <xsl:choose>
          <xsl:when test='$form-input/id/text()'>
            
            <h1>Rec <xsl:value-of select='$form-input/id'/></h1>
            
            <xsl:call-template name='menu'/>
            
          </xsl:when>
          <xsl:otherwise>
            
            <h1>Get info about a record</h1>
            
          </xsl:otherwise>
        </xsl:choose>
        
        
        <xsl:if test='$dot/conflict'>
          <p class='conflict'><big>This record is in a conflict.</big></p>
        </xsl:if>
        
        <xsl:if test='$dot/record'>
          
          <xsl:apply-templates select='$dot/record' mode='dump'/>
          
        </xsl:if>
        
        <xsl:if test='$dot/history'>
          
          <xsl:for-each select='$dot/history'>
            
            <h2>Type</h2>
            
            <p><xsl:value-of select='type/text()'/></p>


            <h2>Present</h2>

            <table class='list'>
              <tr><th>file</th><th>pos</th>
              <th>checksum</th><th>time</th>
              </tr>

              <xsl:for-each select='present/list-item'>
                <tr>
                  <td><xsl:value-of select='list-item[1]/text()'/></td>
                  <td><xsl:value-of select='list-item[2]/text()'/></td>
                  <td><xsl:value-of select='list-item[3]/text()'/></td>
                  <td><xsl:value-of select='list-item[4]/text()'/></td>
                </tr>
              </xsl:for-each>
              
            </table>


            <h2>History</h2>
            
            <table class='list'>
              <tr><th>time</th><th>event</th>
              <th>file</th><th>pos</th><th>sum</th>
              </tr>
              <xsl:for-each select='history/list-item'>
                <tr>
                  <td><xsl:value-of select='list-item[1]/text()'/></td>
                  <td><xsl:value-of select='list-item[2]/text()'/></td>
                  <td><xsl:value-of select='list-item[3]/text()'/></td>
                  <td><xsl:value-of select='list-item[4]/text()'/></td>
                  <td><xsl:value-of select='list-item[5]/text()'/></td>
                </tr>
              </xsl:for-each>
              
            </table>
            
            
            <h2>Last Processed</h2>

            <p><xsl:value-of select='last_processed'/></p>
            
            

          </xsl:for-each>
          
        </xsl:if>

        
        <xsl:text> </xsl:text>

        <form class='xxx-wide'>
          
          <h2>Find a record</h2>
          
          <p>
            <label for='col'>collection: </label>
            <input type='text' id='col' name='col' size='12'/>
            <br/>
            
            <label for='id'>id: </label>
            <input type='text' id='id' name='id' size='60'/>
            
            <xsl:text> </xsl:text>

            <br/>
            <input type='submit' value='GO!' />
          </p>
          
        </form>
        
        <xsl:call-template name='adm-menu'/>
        
      </xsl:with-param>
      
    </xsl:call-template>
</xsl:template>


  <xsl:template match='*[list-item]' mode='dump'>
    <p><xsl:value-of select='name()'/></p>
    <table class='list'>
      <xsl:for-each select='list-item'>
        <tr><td><xsl:apply-templates mode='dump'/></td></tr>
      </xsl:for-each>
    </table>
  </xsl:template>


  <xsl:template match='*' mode='dump'>
    <xsl:choose>
      
      <xsl:when test='*'>
        <p><xsl:value-of select='name()'/></p>
        <ul>
          <xsl:for-each select='*'>
            <li><xsl:apply-templates select='current()' mode='dump'/></li>
          </xsl:for-each>
        </ul>
      </xsl:when>

      <xsl:otherwise>
        <p><xsl:value-of select='name()'/>: <xsl:value-of select='text()'/></p>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>



</xsl:stylesheet>