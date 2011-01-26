<xsl:stylesheet
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
  xmlns:exsl='http://exslt.org/common'
  xmlns:acis='http://acis.openlib.org'
  xmlns:docrel='http://acis.openlib.org/2007/doclinks-relations'
  xmlns='http://amf.openlib.org'
  exclude-result-prefixes="exsl xml acis #default"
  version='1.0'>
  <xsl:import href='../global.xsl'/>
  <xsl:import href='../indent.xsl'/>
  <xsl:output method='xml'
              encoding='utf-8'/>
  <!-- cardiff -->
  <xsl:variable name='person-roles'>
    <author/>
    <editor/>
    <publisher/>
  </xsl:variable>  
  <xsl:template match='text()'/>  
  <xsl:template match='/data'>
    <amf xmlns='http://amf.openlib.org'
         xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
         xsi:schemaLocation="http://amf.openlib.org http://amf.openlib.org/2001/amf.xsd">
      <xsl:apply-templates select='//record'/>
    </amf>
  </xsl:template>
  <xsl:template match='//record[id and type="person"]'>
    <xsl:variable name='record'
                  select='.'/>
    <xsl:variable name='citations'
                  select='citations/identified'/>
    <person xmlns='http://amf.openlib.org'
            id='{id}'>
      <name>
        <xsl:value-of select='name/full'/>
      </name>
      <xsl:if test='name/prefix/text()'>
        <nameprefix>
          <xsl:value-of select='name/prefix'/>
        </nameprefix>
      </xsl:if>
      <givenname>
        <xsl:value-of select='name/first'/>
      </givenname>
      <xsl:if test='name/middle/text()'>
        <additionalname>
          <xsl:value-of select='name/middle'/>
        </additionalname>
      </xsl:if> 
      <familyname>
        <xsl:value-of select='name/last'/>
      </familyname>
      <xsl:if test='name/suffix/text()'>
        <namesuffix>
          <xsl:value-of select='name/suffix'/>
        </namesuffix>
      </xsl:if>
      <xsl:if test='contact/email/text() and contact/email-pub="true"'>
        <email>
          <xsl:value-of select='contact/email'/>
        </email>
      </xsl:if>
      <xsl:if test='contact/homepage/text()'>
        <homepage>
          <xsl:value-of select='contact/homepage'/>
        </homepage>
      </xsl:if>
      <xsl:if test='contact/postal/text()'>
        <postal>
          <xsl:value-of select='contact/postal'/>
        </postal>
      </xsl:if>
      <xsl:if test='contact/phone/text()'>
        <phone>
          <xsl:value-of select='contact/phone'/>
        </phone>
      </xsl:if>
      <xsl:if test='contact/fax/text()'>
        <fax>
          <xsl:value-of select='contact/fax'/>
        </fax>
      </xsl:if>
      <xsl:if test='$response-data/affiliations/list-item'>
        <ispartof>
          <xsl:for-each select='$response-data/affiliations/list-item'>
            <organization>
              <xsl:if test='id/text()'>
                <xsl:attribute name='ref'>
                  <xsl:value-of select='id'/>
                </xsl:attribute>
              </xsl:if>
              <name>
                <xsl:value-of select='name'/>
              </name>
              <xsl:if test='name-english/text()'>
                <name xml:lang='en'>
                  <xsl:value-of select='name-english'/>
                </name>
              </xsl:if>
              <xsl:if test='homepage/text()'>
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
        <xsl:when test='$response-data/name/additional-variations/list-item'>
          <acis:names>
            <xsl:for-each select='$response-data/name/additional-variations/list-item'>
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
      <xsl:if test='contributions/accepted/list-item'>
        <xsl:call-template name='accepted-texts'>
          <xsl:with-param name='current'
                          select='contributions/accepted'/>
          <xsl:with-param name='citations'
                          select='$citations'/>
        </xsl:call-template>
      </xsl:if>
      <xsl:if test='contributions/refused/list-item'>
        <xsl:call-template name='refused-texts'>
          <xsl:with-param name='current'
                          select='contributions/refused'/>
          <xsl:with-param name='citations'
                          select='$citations'/>
        </xsl:call-template>
      </xsl:if>
      <acis:shortid>
        <xsl:value-of select='sid'/>
      </acis:shortid>
    </person>
    <!-- doclinks  -->
    <xsl:variable name='doclinks-conf' 
                  select='$response-data/doclinks-conf'/>
    <xsl:comment> doclinks </xsl:comment>
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
    <xsl:variable name='role-list'
                  select='$response-data/role-list'/>        
    <xsl:for-each select='$role-list/list-item'>
      <xsl:variable name='role'
                    select='text()'/>            
      <xsl:if test='$current/list-item[role=$role] and exsl:node-set($person-roles)/*[name()=$role]'>
        <xsl:variable name='works'
                      select='$current/list-item[role=$role]'/>
        <xsl:element name='is{$role}of'>
          <xsl:for-each select='$works'>
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
          </xsl:for-each>
        </xsl:element>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  <xsl:template name='refused-texts'>
    <xsl:param name='current'/>
    <xsl:param name='citations'/>
    <xsl:variable name='role-list'
                  select='$response-data/role-list'/>        
    <xsl:variable name='works'
                  select='$current/list-item'/>
    <xsl:element name='acis:hasnoconnectionto'>
      <xsl:for-each select='$works'>
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
        </xsl:for-each>
      </xsl:element>
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
      <xsl:call-template name='allauthors'>
        <xsl:with-param name='author-string'>
          <xsl:value-of select='authors'/>
        </xsl:with-param>
      </xsl:call-template>
    </text>
  </xsl:template>
  <!-- recursive template to split author name string -->
  <xsl:template name='allauthors'>
    <xsl:param name='author-string'/>
    <xsl:choose>
      <xsl:when test='contains($author-string,"&amp;")'>
        <xsl:variable name='author-name'> 
          <xsl:value-of select='substring-before($author-string, ", &amp;")'/>
        </xsl:variable>
        <xsl:variable name='remaining-authors'> 
          <xsl:value-of select='substring-after($author-string, ", &amp;")'/>
        </xsl:variable>
        <xsl:call-template name='author-without-comma'>
          <xsl:with-param name='author-name'>
            <xsl:value-of select='$author-name'/>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:if test='$remaining-authors'>
          <xsl:call-template name='allauthors'>
            <xsl:with-param name='author-name'>
              <xsl:value-of select='$remaining-authors'/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name='author-without-comma'>
          <xsl:with-param name='author-name'>
            <xsl:value-of select='$author-string'/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- author name without trailing comma -->
  <xsl:template name='author-without-comma'>
    <xsl:param name='author-name'/>
    <xsl:variable name='length'>
      <xsl:value-of select='string-length($author-name)'/>
    </xsl:variable>
    <xsl:variable name='last-letter'>
      <xsl:value-of select='substring($author-name,$length)'/>
    </xsl:variable>
    <xsl:variable name='author-name-without-last-letter'>
      <xsl:value-of select='substring($author-name,$last-letter - 1)'/>
    </xsl:variable>
    <xsl:variable name='author-name-without-comma'>
      <xsl:choose>
        <xsl:when test='$last-letter = ","'>              
          <xsl:value-of select='$author-name-without-last-letter'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='$author-name'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <hasauthor>
      <name>
        <xsl:value-of select='$author-name-without-comma'/>
      </name>
    </hasauthor>
  </xsl:template>
</xsl:stylesheet>
