<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    
    exclude-result-prefixes="exsl xml html acis"
    version="1.0">
  
  <xsl:import href='research/listings.xsl'/>
  
  <xsl:variable name='logged-mode-flag'>
    <xsl:if test='$current-screen-id = "personal-overview"'>1</xsl:if>
  </xsl:variable>
  
  <xsl:variable name='logged-mode' select='string-length( $logged-mode-flag )'/>
  
  
  <xsl:variable name='page-class'>profile-page</xsl:variable>
  
  
  <xsl:template name='change-link'>
    <xsl:param name='screen'/>
    <xsl:if test='$logged-mode'>
      <small class='change-link supNav'>(<a ref="@{$screen}">change</a>)</small>
    </xsl:if>
  </xsl:template>
  
  
  <xsl:template name='personal-profile'>
    <xsl:param name='person'/>
    
    <h1 class='name'><xsl:value-of select='$person/name/full'/></h1>
    
    <xsl:if test='$session-type = "user"'>
      <p>Short-id: <span class='value'><xsl:value-of select='$record-sid'/></span>
      </p>
    </xsl:if>
    
    <h2>Names
    <xsl:call-template name='change-link'>
      <xsl:with-param name='screen' select='"name"'/>
    </xsl:call-template>
    </h2>
    
    <table class='values'>
      <tr>
        <td class='fld'>first:</td>
        <td class='val'><xsl:value-of select='$person/name/first'/></td>
      </tr>
      <xsl:if test='$person/name/middle/text()'>
        <tr>
          <td class='fld'>middle:</td>
          <td class='val'><xsl:value-of select='$person/name/middle'/></td>
        </tr>
      </xsl:if>
      <tr>
        <td class='fld'>last:</td>
        <td class='val'><xsl:value-of select='$person/name/last'/></td>
      </tr>
      <xsl:if test='$person/name/suffix/text()'>
        <tr>
          <td class='fld'>suffix:</td>
          <td class='val'><xsl:value-of select='$person/name/suffix'/></td>
        </tr>
      </xsl:if>
      
      <xsl:if test='$person/name/latin/text()'>
        <tr>
          <td class='fld'>in English:</td>
          <td class='val'><xsl:value-of select='$person/name/latin'/></td>
        </tr>
      </xsl:if>

    </table>
    
    
    <xsl:variable name='contact' select='$person/contact'/>
    <xsl:if test='$contact/email-pub/text() or $contact/homepage/text() or $contact/phone/text() or $contact/postal/text()'>
    
      <h2>Contact
      
      <xsl:call-template name='change-link'>
        <xsl:with-param name='screen' select='"contact"'/>
      </xsl:call-template>
      </h2>
      
    <table class='values' summary='info on how to contact the person'>
      
      <xsl:if test='$contact/email-pub/text()'>
        <tr>
          <td class='fld'>email:</td>
          <td class='val'><a email='{$contact/email}'/></td>
        </tr>
      </xsl:if>
      
      <xsl:if test='$contact/homepage/text()'>
        <tr>
          <td class='fld'>homepage:</td>
          <td class='val'><a href='{$contact/homepage}'><xsl:value-of select='$contact/homepage'/></a></td>
        </tr>
      </xsl:if>
      
      <xsl:if test='$contact/phone/text()'>
        <tr>
          <td class='fld'>phone:</td>
          <td class='val'><xsl:value-of select='$contact/phone'/></td>
        </tr>
      </xsl:if>
      
      <xsl:if test='$contact/postal/text()'>
        <tr>
          <td class='fld'>postal address:</td>
          <td class='val'><xsl:value-of select='$contact/postal'/></td>
        </tr>
      </xsl:if>
      
    </table>

  </xsl:if> <!-- if we have any contact info -->

    <xsl:if test='$response-data/affiliations/list-item'>

      <h2>Affiliations

        <xsl:call-template name='change-link'>
          <xsl:with-param name='screen' select='"affiliations"'/>
        </xsl:call-template>
      </h2>
      
      <ul class='institutions'>
        <xsl:apply-templates select='$response-data/affiliations'/>
      </ul>
      
    </xsl:if>

    
    <xsl:if test='$person/contributions/accepted/list-item'>
      
      <xsl:variable name='current'   select='$person/contributions/accepted'/>
      <xsl:variable name='role-list' select='$response-data/role-list'/>
      
      <h2>Research profile
      
      <xsl:call-template name='change-link'>
        <xsl:with-param name='screen' select='"research"'/>
      </xsl:call-template>
      
      </h2>
      
      <xsl:for-each select='$role-list/list-item'>
        
        <xsl:variable name='role' select='text()'/>
        
        <xsl:if test='$current/list-item[role=$role]'>
          <xsl:variable name='works' select='$current/list-item[role=$role]'/>
          
          <p><xsl:value-of select='$role'/> of:</p>
          
          <ul>
            
            <xsl:for-each select='$works'>
              <li>
                <xsl:call-template name='present-resource' xml:space='default'>
                  <xsl:with-param name='resource' select='.'/>
                </xsl:call-template>
              </li>
            </xsl:for-each>
            
          </ul>
          
        </xsl:if>

      </xsl:for-each>


    </xsl:if>


  </xsl:template>


  <xsl:template name='listify'>
    <xsl:param name='string'/>
    <xsl:variable name='item' select='substring-before( $string, "&#xa;" )'/>
    <xsl:variable name='rest' select='substring-after(  $string, "&#xa;" )'/>
    <xsl:if test='$item'>
      <li><xsl:value-of select='$item'/></li>
      <xsl:text>
      </xsl:text>
      <xsl:if test='$rest'>
        <xsl:call-template name='listify'><xsl:with-param name='string' select='$rest'/></xsl:call-template>
      </xsl:if>
    </xsl:if>
    <xsl:if test='not( $item )'> 
      <li><xsl:value-of select='$string'/></li>
    </xsl:if>
  </xsl:template>
  


 <xsl:template match="*" mode='organization-details'>
   <xsl:if test='text()' xml:space='preserve'>
     <li><xsl:value-of select='local-name(.)' />: <xsl:value-of select='text()'/></li>
   </xsl:if>
 </xsl:template>
 
 <xsl:template match='affiliations/list-item|items/list-item' xml:space='default'>

   <xsl:text>
   </xsl:text>
   <li class='institution'>
     <span class='title'><xsl:value-of select='name/text()'/></span>
     
     <!--
         <xsl:choose
         ><xsl:when test='homepage/text()'
         ><a href='{homepage/text()}'><xsl:value-of select='name/text()'/></a
         ></xsl:when
         ><xsl:otherwise><xsl:value-of select='name/text()'/></xsl:otherwise
         ></xsl:choose>
     -->
     
     <ul class='details'>
       <xsl:if test='name-english/text()'>
         <li>English name: <span class='title'>
         <xsl:value-of select='name-english/text()' />
       </span></li></xsl:if>
       
      <xsl:if test='homepage/text()'>
        <li><a href='{homepage/text()}'>website</a></li>
      </xsl:if>

      <xsl:apply-templates select='location' mode='organization-details'/>
      
      <xsl:if test='not(homepage/text())'>
        
        <xsl:if test='email/text()'>
          <li>email: <a href='mailto:{email}'>
          <xsl:value-of select='email/text()'/>
          </a></li>
        </xsl:if>
        
        <xsl:apply-templates select='postal|phone|fax' mode='organization-details'/>
      
      </xsl:if>

   </ul>
  </li>
 </xsl:template>



 <xsl:variable name='to-go-options'/>

</xsl:stylesheet>


<!-- ########################   B A S E M E N T   ###################### -->

<!--
    <xsl:if test='$person/interests/freetext/text()'>
      <h2>Research interests

        <xsl:call-template name='change-link'
           ><xsl:with-param name='screen' select='"interests"'
        /></xsl:call-template>
      </h2>

      <ul class='interests'>
        <xsl:call-template name='listify'
          ><xsl:with-param name='string' select='$person/interests/freetext/text()'
          /></xsl:call-template>
        </ul>

    </xsl:if>
-->

<!--
    <h2>Identifier</h2>

    <p>Record id: <code class='id'><xsl:value-of select='$person/id'/></code></p>
-->

