<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:acis='http://acis.openlib.org'
  version="1.0">

<!--  exclude-result-prefixes='exsl xml x' -->  

  <xsl:import href='../global.xsl'/>
  <xsl:import href='../indent.xsl'/>

  <xsl:output method='xml' encoding='utf-8'/>

  <xsl:variable name='person-roles'>
    <author/>
    <editor/>
    <publisher/>
  </xsl:variable>

  <xsl:template match='text()'/>

<xsl:template match='/data'>
<amf xmlns='http://amf.openlib.org'
     xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
     xsi:schemaLocation="http://amf.openlib.org http://amf.openlib.org/2001/amf.xsd"
     >
<xsl:text>
</xsl:text>
  <xsl:apply-templates select='//record'/>
<xsl:text>
</xsl:text>
</amf>
</xsl:template>

  <xsl:template match='//record[id and type="person"]' 
                xml:space='preserve'
    ><xsl:variable name='citations' select='citations/identified'/>
    <person xmlns='http://amf.openlib.org' id='{id}'>
      <name><xsl:value-of select='name/full'/></name>
<xsl:if test='name/prefix/text()'
>      <nameprefix><xsl:value-of select='name/prefix'/></nameprefix>
</xsl:if
>      <givenname><xsl:value-of select='name/first'/></givenname>
<xsl:if test='name/middle/text()'
>      <additionalname><xsl:value-of select='name/middle'/></additionalname>
</xsl:if
>      <familyname><xsl:value-of select='name/last'/></familyname>
<xsl:if test='name/suffix/text()'
>      <namesuffix><xsl:value-of select='name/suffix'/></namesuffix>
</xsl:if
>
<xsl:if test='contact/email/text() and contact/email-pub="true"'
>      <email><xsl:value-of select='contact/email'/></email>
</xsl:if
><xsl:if test='contact/homepage/text()'
>      <homepage><xsl:value-of select='contact/homepage'/></homepage>
</xsl:if
><xsl:if test='contact/postal/text()'
>      <postal><xsl:value-of select='contact/postal'/></postal>
</xsl:if
><xsl:if test='contact/phone/text()'
>      <phone><xsl:value-of select='contact/phone'/></phone>
</xsl:if
><xsl:if test='contact/fax/text()'
>      <fax><xsl:value-of select='contact/fax'/></fax>
</xsl:if
><xsl:if test='$response-data/affiliations/list-item'>
      <ispartof>
<xsl:for-each select='$response-data/affiliations/list-item'>
        <organization><xsl:if test='id/text()'><xsl:attribute 
        name='ref'><xsl:value-of select='id'/></xsl:attribute
        ></xsl:if>
          <name><xsl:value-of select='name'/></name>
<xsl:if test='name-english/text()'
>         <name xml:lang='en'><xsl:value-of select='name-english'/></name>
</xsl:if
><xsl:if test='homepage/text()'
>          <homepage><xsl:value-of select='homepage'/></homepage>
</xsl:if
>        </organization>
</xsl:for-each
>      </ispartof>
</xsl:if
>
<!--
     research profile 

--><xsl:if test='contributions/accepted/list-item' xml:space='default'>
      <xsl:variable name='current'   select='contributions/accepted'/>
      <xsl:variable name='role-list' select='$response-data/role-list'/>
      
      <xsl:for-each select='$role-list/list-item'>
        <xsl:variable name='role' select='text()'/>

        <xsl:if test='$current/list-item[role=$role] and
                exsl:node-set($person-roles)/*[name()=$role]'>
          <xsl:variable name='works' select='$current/list-item[role=$role]'/>
          <xsl:text>      </xsl:text>
          <xsl:element name='is{$role}of'>
<xsl:text>
</xsl:text>
<xsl:for-each select='$works'>
  <xsl:variable name='dsid' select='sid/text()'/>
  <xsl:choose>
    <xsl:when test='$citations/*[name()=$dsid]/list-item' xml:space='preserve'
>        <text ref='{id}'>
<xsl:for-each select='$citations/*[name()=$dsid]/list-item'
>          <isreferencedby><text ref='{srcdocid}'/></isreferencedby>
</xsl:for-each
>        </text>
</xsl:when>
    <xsl:otherwise xml:space='preserve'
>        <text ref='{id}'/>
</xsl:otherwise>
  </xsl:choose>
</xsl:for-each>
          <xsl:text>      </xsl:text>
          </xsl:element>
<xsl:text>
</xsl:text>
        </xsl:if></xsl:for-each
></xsl:if
>
      <acis:shortid><xsl:value-of select='sid'/></acis:shortid>
    </person>
</xsl:template>



</xsl:stylesheet>