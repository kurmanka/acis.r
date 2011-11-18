<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">

  <xsl:import href='index.xsl'/>
  <xsl:import href='../misc/time.xsl' />


  <xsl:template match='/data'>

    <xsl:variable name='amount' select='count(//session-list/list-item)'/>


    <xsl:call-template name='page'>
      <xsl:with-param name='title'>open sessions</xsl:with-param>

      <xsl:with-param name='content'>
        
        <h1>open sessions</h1>

        <xsl:if test='$amount'>
          <ul>
            <xsl:for-each select='//session-list/list-item'>
            
              <xsl:variable name='minutes' select='round( number( diff/text() ) div 60 )' />
              <xsl:variable name='hours'   select='round( $minutes div 60 )' />

              
              <li>
                <a ref='adm/session?id={id}' >
                  <xsl:value-of select='id'/></a>,
                  
                  <span class='name' title='{login}'>
                  <xsl:value-of select='owner'/></span>
                  
                  <xsl:text/> [<xsl:value-of select='type'/>]<xsl:text/>
                  <xsl:text>, </xsl:text>
                  
                  <xsl:call-template name='time-difference-in-seconds'>
                    <xsl:with-param name='diff' select='diff/text()'/>
                  </xsl:call-template>

                  <xsl:text> old, </xsl:text>
                  
                  <!--
                      <xsl:choose>
                      <xsl:when test='$hours &gt; 2'>
                      <xsl:value-of select='$hours'/> hours
                      </xsl:when>
                      <xsl:otherwise>
                      <xsl:value-of select='$minutes'/> minutes
                      </xsl:otherwise>
                      </xsl:choose> old,
                  -->
                  
                  <xsl:if test='type/text() ="user"'>
                  <a ref='welcome!{id}' >menu</a>, </xsl:if>
                  
                  <a ref='profile-overview!{id}'>overview</a>,
                  <a ref='adm/session?action=delete&amp;id={id}'>delete</a>.
              </li>
            </xsl:for-each>
          </ul>
        </xsl:if>
        
        <xsl:call-template name='adm-menu'/>


      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>

