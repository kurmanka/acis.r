<xsl:stylesheet
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:exsl='http://exslt.org/common'
    exclude-result-prefixes='exsl xsl'
    version='1.0'>  

  <!-- This is the global "page" template -->
  <!-- has the global variables, error and handling -->
  <xsl:import href='../global.xsl'/>
  <!-- has the fieldset templates -->
  <xsl:import href='../forms.xsl'/>

  <xsl:output method="xml"
              omit-xml-declaration='no'
              encoding='utf-8' />

<!-- XRDS: 

     - http://en.wikipedia.org/wiki/XRDS

     - Spec: http://www.oasis-open.org/committees/download.php/17293
       Section 3: XRDS
   
     - Also: http://openid.net/specs/openid-authentication-2_0.html#XRDS_Sample
  
     - And: http://ru.wikipedia.org/wiki/Yadis

-->

  <xsl:template match='/'>
    <XRDS xmlns="xri://$xrds"> 
      <XRD xmlns="xri://$xrd*($v*2.0)" version="2.0"> 

<xsl:text>
</xsl:text>

        <Service> 
          <Type>http://specs.openid.net/auth/2.0/server</Type> 
          <URI><xsl:value-of select='$base-url'/>/openid</URI> 
       </Service> 

       <xsl:if test='//sid'>
<xsl:text>
</xsl:text>
         <Service> 
           <Type>http://specs.openid.net/auth/2.0/signon</Type> 
           <!-- this is a little risky: the URL might be different -->
           <URI><xsl:value-of select='$base-url'/>/openid</URI> 
<!--
           <URI><xsl:value-of select='$base-url'/>/pro/<xsl:value-of select='//sid'/>/</URI> 
 -->
           <LocalID><xsl:value-of select='$base-url'/>/pro/<xsl:value-of select='//sid'/>/</LocalID> 

         </Service> 
       </xsl:if>

<xsl:text>
</xsl:text>

      </XRD>
    </XRDS>

  </xsl:template>


</xsl:stylesheet>