<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:acis="http://acis.openlib.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xml html acis #default"
    version="1.0">
  
  
  <xsl:variable name='fields-table' select='document("fields.xml")'/>
  
  
  <!-- ToK 2008-03-29
       This file sets out the fieldset mode. This treat
       treat elements that are in the acis:name space.
       These are acis:form, acis:input, acis:select
       and acis:textarea. Not all occurances of
       for form, input, select and textarea are in
       this namespace.

       These templates implement sticky forms, by
       adding reponses from acis into the forms.

  -->
  
  <xsl:template name='fieldset'>
    <xsl:param name='content'/>
    <xsl:apply-templates mode='fs' select='exsl:node-set($content)' />
  </xsl:template>
  
  
  <xsl:template match='acis:form' mode='fs'>
    <acis:form xsl:use-attribute-sets='form'>
      <xsl:copy-of select='@*'/>
      <!--  trying to get rid of the name attribute on the form 
           <xsl:for-each select='@*'>
           д<xsl:value-of select='.'/>д
           <xsl:if test='local-name(.)=name'>
           namehere
           <xsl:value-of select='.'/>
           </xsl:if>
           </xsl:for-each>
      -->
      <xsl:apply-templates mode='fs'/>
    </acis:form>
  </xsl:template>
  
  <xsl:template match='acis:input[@type="text" 
                       or @type="password" 
                       or not(@type)]' 
                mode='fs'>
    <xsl:variable name='name' select='@name'/>
    <!-- creates another input with the no namespace -->
    <xsl:element name='input'>
      <xsl:copy-of select='@*'/>
      <xsl:if test='not( @class )'>
        <xsl:attribute name='class'>edit</xsl:attribute>
      </xsl:if>
      <xsl:if test='not( @type )'>
        <xsl:attribute name='type'>text</xsl:attribute>
      </xsl:if>
      <xsl:if test='not (@type="password") and not(@value)'>
        <xsl:attribute name='value'>
          <xsl:value-of select='$form-values/*[name()=$name]/text()'/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test='$form-errors//list-item=$name'>
        <xsl:attribute name='class'>edit highlight</xsl:attribute>
      </xsl:if>

      <xsl:apply-templates mode='fs'/>
      
    </xsl:element>
  </xsl:template>
  
  
  <xsl:template match='acis:select' mode='fs'>
    <xsl:element name='select'>
      <xsl:copy-of select='@*'/>
      <xsl:attribute name='class'>
        <xsl:choose>
          <xsl:when test='$form-errors//list-item=current()/@name'>edit highlight</xsl:when>
          <xsl:when test='not( @class )'>edit</xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='@class'/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates mode='fs'/>
    </xsl:element>
  </xsl:template>
  
  <!-- checkbox -->
  
  <xsl:template match='acis:input[@type="checkbox"]' mode='fs'>
    <xsl:variable name='name' select='@name'/>
    <xsl:element name='input'>
      <xsl:copy-of select='@*'/>
      <xsl:if test='$form-values/*[name()=$name]/text()'>
        <xsl:attribute name='checked'>1</xsl:attribute>
      </xsl:if>
      <xsl:attribute name='value'>true</xsl:attribute>
      <xsl:attribute name='class'>checkbox</xsl:attribute>
    </xsl:element>
  </xsl:template>
  
  
  
  <!-- radio -->
  <xsl:template match='acis:input[@type="radio"]' mode='fs'>
    <xsl:variable name='name' select='@name'/>
    <xsl:element name='input'>
      <xsl:copy-of select='@type|@id|@name|@value'/>      
      <xsl:choose>        
        <xsl:when test='not( $form-values/*[name()=$name] )
                        or $form-values/*[name()=$name]/undef'>          
          <xsl:if test='@checked'>
            <xsl:attribute name='checked'>checked</xsl:attribute>
          </xsl:if>          
        </xsl:when>        
        <xsl:otherwise>          
          <xsl:if test='$form-values/*[name()=$name]/text() = @value'>
            <xsl:attribute name='checked'>checked</xsl:attribute>
          </xsl:if>          
        </xsl:otherwise>        
      </xsl:choose>
      
      <!-- XX meaningless ? -->
      
      <xsl:attribute name='class'>radio</xsl:attribute>      
      <xsl:if test='contains($form-errors//list-item/text(), $name)'>
        <xsl:attribute name='class'>radio highlight</xsl:attribute>
      </xsl:if>    
    </xsl:element>
  </xsl:template>
  
  
  <!-- hidden -->
  <xsl:template match='acis:input[@type="hidden"]' mode='fs'>
    <xsl:variable name='name' select='@name'/>
    <xsl:element name='input'>
      <xsl:copy-of select='@*'/>
      <xsl:if test='not (@value)'>
        <xsl:attribute name='value'>
          <xsl:value-of select='$form-values/*[name()=$name]/text()'/>
        </xsl:attribute>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  
  
  <!-- textarea -->
  <xsl:template match='acis:textarea' mode='fs'>
    <xsl:variable name='name' select='@name'/>
    <xsl:element name='textarea'>
      <xsl:attribute name='class'>edit</xsl:attribute>
      <xsl:copy-of select='@*'/>
      <xsl:if test='contains($form-errors//list-item/text(), $name)'>
        <xsl:attribute name='class'>highlight edit</xsl:attribute>
      </xsl:if>
      <xsl:value-of select='$form-values/*[name()=$name]/text()'/>
    </xsl:element>
  </xsl:template>
  
  
  <!-- catch all -->
  
  <xsl:template match='*' mode='fs'>
    <xsl:element name='html:{local-name()}'>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode='fs'/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match='*' mode='fs'>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode='fs'/>
    </xsl:copy>
  </xsl:template>
  
 
</xsl:stylesheet>

