<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xsl acis html"
    xmlns:acis='http://acis.openlib.org'
    version="1.0">


  <!-- GLOBAL VARIABLES  --> 
  
  <!-- main ones -->
  
  <xsl:variable name='acis:root'  select='/'/>
  <xsl:variable name='system'     select='/data/system'/>
  <xsl:variable name='config'     select='/data/system/config'/>
  <xsl:variable name='request'    select='/data/request'/>
  <xsl:variable name='response'   select='/data/response'/>

  <!-- configuration -->

  <xsl:variable name='base-url'   select='$config/base-url/text()'/>
  <xsl:variable name='css-url'    select='$config/css-url/text()'/>
  <xsl:variable name='help-url'   select='$config/help-url/text()'/>
  <xsl:variable name='site-name'  select='$config/site-name/text()'/>
  <xsl:variable name='site-name-long' select='$config/site-name-long/text()'/>
  <xsl:variable name='admin-email'    select='$config/admin-email/text()'/>
  <xsl:variable name='system-email'   select='$config/system-email/text()'/>
  <xsl:variable name='debug-mode' select='$config/debug/text()'/>
  <xsl:variable name='static-base-url'    select='$config/static-base-url/text()'/>
  <xsl:variable name='problem-report-url' select='$config/problem-report-url/text()'/>
  <xsl:variable name='auto-search-disabled' select='$config/research-auto-search-disabled/text()'/>
  <xsl:variable name='RAS-mode'   select='$config/service-mode/text() = "ras"' />


  <xsl:variable name='home-url'>
    <xsl:choose>
      <xsl:when test='$config/home-url'>
	<xsl:value-of select='$config/home-url/text()'/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select='$base-url'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  
  
  <!-- request parts -->
  
  <xsl:variable name='session'    select='$request/session'/>
  <xsl:variable name='user'       select='$request/user'/>
  <xsl:variable name='user-agent' select='$request/agent'/>
  
  <!-- request context and details -->
  
  <xsl:variable name='session-id'   select='$session/id/text()'  />
  <xsl:variable name='session-type' select='$session/type/text()'/>
  <xsl:variable name='current-record' select='$session/current-record'/>
  
  <xsl:variable name='record-id'    select='$current-record/id/text()'  />
  <xsl:variable name='record-type'  select='$current-record/type/text()'/>
  <xsl:variable name='record-name'  select='$current-record/name/text()'/>
  <xsl:variable name='record-sid'   select='$current-record/shortid/text()'/>
  
  <xsl:variable name='user-name'    select='$user/name/text()'/>
  <xsl:variable name='user-login'   select='$user/login/text()'/>
  <xsl:variable name='user-type'    select='$user/type'/>
  <xsl:variable name='user-pass'    select='$user/pass/text()'/>
  
  <xsl:variable name='form-input'   select='$request/form/input'/>
  
  <xsl:variable name='request-screen'    select='$request/screen/text()' />
  <xsl:variable name='request-subscreen' select='$request/subscreen/text()' />
  <xsl:variable name='referer'           select='$request/referer/text()'/>
  


  <!-- response details -->
  
  <xsl:variable name='error'   select='$response/error/text()'/>
  <xsl:variable name='message' select='$response/message/text()'/>
  <xsl:variable name='success' select='$response/success/text()'/>
  <xsl:variable name='refresh' select='$response/refresh'/>
  <xsl:variable name='refresh-url'   select='$response/refresh/url/text()'/>
  <xsl:variable name='response-data' select='$response/data'/>
  <xsl:variable name='dot'         select='$response/data'/>
  <xsl:variable name='form-action' select='$response/form/action/text()'/>
  <xsl:variable name='form-values' select='$response/form/values'/>
  <xsl:variable name='form-errors' select='$response/form/errors'/>


  <!--  other utility variables  -->

  <xsl:variable name='any-errors' select='$error or $form-errors//list-item'/>
  
  
  <xsl:variable name='record-about-owner-flag'>
    <xsl:choose>
      <xsl:when test='$current-record/about-owner/text()="yes"'>yes</xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name='record-about-owner' select="string-length( $record-about-owner-flag )"/>


  <!--  I need to have simple-user flag variable -->
  
  <xsl:variable name='advanced-user' select='$user-type/advanced'/>
  <xsl:variable name='simple-user'   select='not( $user-type/advanced )'/>
  
  
  <!--  utility URLs  -->
  
  <xsl:variable name='menu-url'>
    <xsl:value-of select='$base-url'/>/welcome!<xsl:value-of select='$session-id'/>
  </xsl:variable>
  
  
  <xsl:variable name='phrase'       select='document( "../phrase.xml" )/acis:phrasing' />
  <xsl:variable name='phrase-local' select='document( "../phrase-local.xml" )/acis:phrasing' />
  
  <xsl:template name='req'>
    <span class='req'>required</span>
  </xsl:template>
  
  
  <!--  SHOW  ERRORS  template  -->
  
  
  <xsl:template name='show-errors'>
    
    <xsl:param name='fields-spec-uri' />
    
    <xsl:variable name='errors-table' select='document( "errors.xml" )' />
    <xsl:variable name='fields-table' select='document( $fields-spec-uri )' />

    <div class='errors'>
      <xsl:if test='$error'>

        <p>Error: <xsl:text/>
        
        <xsl:choose>
          <xsl:when test='$errors-table//acis:error[@id=$error]'>
            <xsl:apply-templates mode='message' select='$errors-table//acis:error[@id=$error]'/>
          </xsl:when>
          <xsl:otherwise>
	    undescribed, code: <xsl:value-of select='$error'/>
	  </xsl:otherwise>
	</xsl:choose>
	</p>
	
      </xsl:if>
      
      <xsl:if test='/data/errors/list-item'>
	
	<p>Errors: (this should not be! XXX)</p>
	
      </xsl:if>
      
      <xsl:if test='$form-errors/required-absent/list-item'>
	
	<xsl:variable name='list'>
	  <xsl:for-each select='$form-errors/required-absent/list-item'>
	    <xsl:variable name='field' select='text()'/>
	    <xsl:variable name='desc' select='$fields-table//acis:field[@name=$field]/acis:desc'/>
	    <xsl:if test='$desc'>	      
	      <li>
		<xsl:value-of select='$desc/text()'/>
	      </li>	      
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>

        <xsl:if test='exsl:node-set( $list )/li'>
          <p>Please provide values for these fields:</p>
          <ul>
            <xsl:copy-of select='$list'/>
          </ul>
        </xsl:if>
      </xsl:if>

      <xsl:if test='$form-errors/invalid-value/list-item'>

        <p>
	  The values you entered into these fields are invalid:
	</p>
	<ul>	  
	  <xsl:for-each select='$form-errors/invalid-value/list-item'>
	    <xsl:variable name='field' select='text()'/>
            <xsl:variable name='desc' 
			  select='$fields-table//acis:field[@name=$field]/acis:desc/text()'/>
	    <li>
	      <xsl:choose>
		<xsl:when test='string-length($desc)'>
		  <xsl:value-of select='$desc'/>
                </xsl:when>
		<xsl:otherwise>
		  <xsl:value-of select='$field'/>
		</xsl:otherwise>
	      </xsl:choose>
	    </li>

	  </xsl:for-each>
	  
        </ul>
	
      </xsl:if>
    </div>
  </xsl:template>
  
  

  <!--  SHOW  STATUS  -->

  <xsl:template name='show-status'>

    <xsl:param name='fields-spec-uri' select='"fields.xml"'/>

    
    <div class='status'>

      <xsl:if test='$any-errors'>
        <xsl:call-template name='show-errors'>
          <xsl:with-param name='fields-spec-uri' select='$fields-spec-uri'/>
        </xsl:call-template>
      </xsl:if>

      <xsl:if test='$message'>
        <xsl:variable name='msg-table' select='document("messages.xml")'/>

        <div class='msg'>
          <xsl:choose>
            <xsl:when test='$msg-table//acis:message[@id=$message]'>

              <p><xsl:apply-templates mode='message'
              select='$msg-table//acis:message[@id=$message]'/></p>

            </xsl:when>
            <xsl:otherwise>
              <p>Undescribed message, code: <xsl:value-of select='$message'/></p>
            </xsl:otherwise>
          </xsl:choose>
        </div>

      </xsl:if>
    </div>
  
  </xsl:template>


  <xsl:template mode='message' match='*|@*'>
    <xsl:copy>
      <xsl:apply-templates mode='message'/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode='message' match='acis:message|acis:error'>
    <xsl:apply-templates mode='message'/>
  </xsl:template>

 
 <xsl:attribute-set name='form'>
  <xsl:attribute name='action'>
   <xsl:choose>
     <xsl:when test='string-length($form-action)'>
       <xsl:value-of select='$form-action'/>
     </xsl:when>
     <xsl:otherwise><!-- #top --></xsl:otherwise>
    </xsl:choose>
   </xsl:attribute>
  <xsl:attribute name='method'>post</xsl:attribute>
  <xsl:attribute name='enctype'>application/x-www-form-urlencoded</xsl:attribute>
  <xsl:attribute name='accept-charset'>utf-8</xsl:attribute>
 </xsl:attribute-set>


 <xsl:template name='connector'>&#xBB;</xsl:template>



<!--

<xsl:template name='email'>
  <xsl:param name='address'/>
  <xsl:param name='label' select='$address'/>
  
  <xsl:variable name='userpart' select='substring-before( $address, "@" )'/>
  <xsl:variable name='hostpart' select='substring-after( $address, "@" )'/>

  <a href='mailto:[[{$userpart}&#xff20;{$hostpart}]]'><xsl:value-of select='$label'/></a>

</xsl:template>
-->


</xsl:stylesheet>