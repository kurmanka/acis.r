<xsl:stylesheet
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
  xmlns:exsl='http://exslt.org/common'
  xmlns:acis='http://acis.openlib.org'
  xmlns:amf='http://amf.openlib.org'
  xmlns:docrel='http://acis.openlib.org/2007/doclinks-relations'
  xmlns='http://amf.openlib.org'
  exclude-result-prefixes='exsl xml amf acis'
  version='1.0'>
  <xsl:import href='../global.xsl'/>
  <xsl:import href='../indent.xsl'/>
  <xsl:import href='../person/research/person-listings.xsl'/>
  <xsl:output method='xml'
              encoding='utf-8'/>
  <xsl:variable name='person-roles'>
    <author/>
    <editor/>
    <publisher/>
  </xsl:variable>  
  <xsl:template match='text()'/>  
  <xsl:template match='/'>
    <amf xmlns='http://amf.openlib.org'
         xmlns:acis='http://acis.openlib.org'
         xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
         xsi:schemaLocation="http://amf.openlib.org http://amf.openlib.org/2001/amf.xsd">
      <xsl:for-each select='//records'>
        <xsl:if test='./list-item/about-owner/text() = "yes"'>
          <xsl:call-template name='amf-person'>
            <xsl:with-param name='record'
                            select='./list-item'/>
            <xsl:with-param name='input-data'
                            select='$response-data'/>
            <xsl:with-param name='citations'
                            select='citations/identified'/>
          </xsl:call-template>
        </xsl:if>
      </xsl:for-each>
    </amf>
  </xsl:template>
  <xsl:template name='amf-person'>
    <xsl:param name='record'/>
    <xsl:param name='citations'/>
    <xsl:param name='input-data'/>
    <person>
      <xsl:attribute name='id'>
        <xsl:value-of select='$record/id/text()'/>
      </xsl:attribute>
      <name>
        <xsl:value-of select='$record/name/full'/>
      </name>
      <xsl:if test='$record/name/prefix/text()'>
        <nameprefix>
          <xsl:value-of select='$record/name/prefix'/>
        </nameprefix>
      </xsl:if>
      <givenname>
        <xsl:value-of select='$record/name/first'/>
      </givenname>
      <xsl:if test='$record/name/middle/text()'>
        <additionalname>
          <xsl:value-of select='$record/name/middle'/>
        </additionalname>
      </xsl:if> 
      <familyname>
        <xsl:value-of select='$record/name/last'/>
      </familyname>
      <xsl:if test='$record/name/suffix/text()'>
        <namesuffix>
          <xsl:value-of select='$record/name/suffix'/>
        </namesuffix>
      </xsl:if>
      <xsl:if test='$record/contact/email/text() and $record/contact/email-pub="true"'>
        <email>
          <xsl:value-of select='$record/contact/email'/>
        </email>
      </xsl:if>
      <xsl:if test='$record/contact/homepage/text()'>
        <homepage>
          <xsl:value-of select='$record/contact/homepage'/>
        </homepage>
      </xsl:if>
      <xsl:if test='$record/contact/postal/text()'>
        <postal>
          <xsl:value-of select='$record/contact/postal'/>
        </postal>
      </xsl:if>
      <xsl:if test='$record/contact/phone/text()'>
        <phone>
          <xsl:value-of select='$record/contact/phone'/>
        </phone>
      </xsl:if>
      <xsl:if test='$record/contact/fax/text()'>
        <fax>
          <xsl:value-of select='$record/contact/fax'/>
        </fax>
      </xsl:if>
      <xsl:if test='$record/sid/text()'>
        <acis:shortid>
          <xsl:value-of select='$record/sid/text()'/>
        </acis:shortid>
      </xsl:if>
      <xsl:if test='$record/affiliations/list-item'>
        <ispartof>
          <xsl:for-each select='$record/affiliations/list-item'>
            <organization>
              <xsl:if test='./id/text()'>
                <xsl:attribute name='ref'>
                  <xsl:value-of select='./id/text()'/>
                </xsl:attribute>                                  
              </xsl:if>
              <xsl:if test='./name/text()'>
                <name>
                  <xsl:value-of select='name'/>
                </name>
              </xsl:if>
              <xsl:if test='./name-english/text()'>
                <name xml:lang='en'>
                  <xsl:value-of select='name-english'/>
                </name>
              </xsl:if>
              <xsl:if test='./homepage/text()'>
                <homepage>
                  <xsl:value-of select='homepage'/>
                </homepage>
              </xsl:if>
            </organization>
          </xsl:for-each>
        </ispartof>
      </xsl:if>
      <!-- name variations -->
      <xsl:choose>
        <xsl:when test='$record/name/variations/list-item'>
          <acis:names>
            <xsl:for-each select='$record/name/variations/list-item'>
              <acis:variation>
                <xsl:value-of select='.'/>
              </acis:variation>
            </xsl:for-each>
          </acis:names>
        </xsl:when>
        <xsl:otherwise>
          <acis:no_additional_names/>
        </xsl:otherwise>
      </xsl:choose>
      <!--  research profile -->
      <xsl:if test='$record/contributions/accepted/list-item'>
        <xsl:call-template name='accepted-texts'>
          <xsl:with-param name='current'
                          select='$record/contributions/accepted'/>
          <xsl:with-param name='citations'
                          select='$citations'/>
          <xsl:with-param name='record'
                          select='$record'/>
        </xsl:call-template>
      </xsl:if>
      <xsl:if test='$record/contributions/refused/list-item'>
        <xsl:call-template name='refused-texts'>
          <xsl:with-param name='current'
                          select='$record/contributions/refused'/>
          <xsl:with-param name='citations'
                          select='$citations'/>
          <xsl:with-param name='input-data'
                          select='$input-data'/>
        </xsl:call-template>
      </xsl:if>
      <xsl:text>&#x0a;</xsl:text>
    </person>
    <xsl:variable name='doclinks-conf' 
                  select='$input-data/doclinks-conf'/>
    <xsl:for-each select='doclinks/list-item'>
      <xsl:variable name='srcdocsid'
                    select='list-item[1]/text()'/>
      <xsl:variable name='relation' 
                    select='list-item[2]/text()'/>
      <xsl:variable name='trgdocsid'
                    select='list-item[3]/text()'/>
      <xsl:variable name='srcdocid'
                    select='$record/contributions/accepted/list-item[sid=$srcdocsid]/id'/>
      <xsl:variable name='trgdocid'
                    select='$record/contributions/accepted/list-item[sid=$trgdocsid]/id'/>
      <xsl:variable name='relation-amf'
                    select='$doclinks-conf/*[name()=$relation]/amf-verb/text()'/>
      <text xmlns='http://amf.openlib.org'
            ref='{$srcdocid}'>
        <xsl:choose>
          <xsl:when test='$relation-amf'>
            <xsl:element name='{$relation-amf}'>
              <text ref='{$trgdocid}'/>
            </xsl:element>
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name='doclinks:{$relation}'>
              <text ref='{$trgdocid}'/>
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
      </text>
    </xsl:for-each>
  </xsl:template>    
  <xsl:template name='accepted-texts'>
    <xsl:param name='current'/>
    <xsl:param name='citations'/>
    <xsl:param name='record'/>
    <xsl:variable name='works'
                  select='$current/list-item'/>
    <xsl:for-each select='$works'>
      <xsl:text>&#x0a;</xsl:text>
      <xsl:variable name='role'
                  select='role'/>
      <xsl:element name='is{$role}of'>
        <xsl:variable name='dsid'
                      select='sid/text()'/>
        <xsl:choose>
          <xsl:when test='$citations/*[name()=$dsid]/list-item'>
            <text ref='{id}'>
              <xsl:for-each select='$citations/*[name()=$dsid]/list-item'>
                <isreferencedby>
                  <text ref='{srcdocid}'/>
                </isreferencedby>
              </xsl:for-each>
            </text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name='text'>
              <xsl:with-param name='text'
                              select='.'/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
    </xsl:for-each>          
  </xsl:template>
  <xsl:template name='refused-texts'>
    <xsl:param name='current'/>
    <xsl:param name='citations'/>
    <xsl:param name='record'/>
    <xsl:variable name='works'
                  select='$current/list-item'/>
    <xsl:for-each select='$works'>
      <xsl:text>&#x0a;</xsl:text>
      <xsl:element name='acis:hasnoconnectionto'>
        <xsl:variable name='dsid'
                      select='sid/text()'/>
        <xsl:choose>
          <xsl:when test='$citations/*[name()=$dsid]/list-item'>
            <text ref='{id}'>
              <xsl:for-each select='$citations/*[name()=$dsid]/list-item'>
                <isreferencedby>
                  <text ref='{srcdocid}'/>
                </isreferencedby>
              </xsl:for-each>
            </text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name='text'>
              <xsl:with-param name='text'
                              select='.'/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  <!-- template to convert texts -->
  <xsl:template name='text'>
    <xsl:param name='text'/>
    <text>
      <xsl:attribute name='ref'>
        <xsl:value-of select='$text/id'/>
      </xsl:attribute>
      <title>
        <xsl:value-of select='$text/title'/>
      </title>
      <displaypage>
        <xsl:value-of select='$text/url-about'/>
      </displaypage>
      <!-- defined in person-listings.xsl -->
      <xsl:call-template name='all-person-names'>
        <xsl:with-param name='name-string'>
          <xsl:value-of select='authors'/>
        </xsl:with-param>
        <xsl:with-param name='separator'/>
      </xsl:call-template>
    </text>
  </xsl:template>
  <!-- needs to be defined for person-listings.xsl to work -->
  <xsl:template name='what-to-do-with-person-name'>
    <xsl:param name='person-name'/>
    <!-- fixme: this needs to take account of different roles -->
    <hasauthor>
      <person>
        <name>
          <xsl:value-of select='$person-name'/>
        </name>
      </person>
    </hasauthor>
  </xsl:template>
  <!-- organization template -->
  <xsl:template name='organization'>
    <xsl:param name='org'/>
    <organization>
      <xsl:if test="$org/list-item">
      </xsl:if>
      <!--
      <xsl:choose>
          <xsl:attribute name='ref'>
            <xsl:value-of select='$org'/>
          </xsl:attribute>                                            
        </xsl:otherwise>
      </xsl:choose>      
      -->
      <xsl:copy-of select="$org"/>
    </organization>
  </xsl:template>
</xsl:stylesheet>
