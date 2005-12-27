<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">

  
  <xsl:variable name='fields-table' select='document("fields.xml")'/>
    

 <!--  fieldset  -->

 <xsl:template name='fieldset'>
   <xsl:param name='content'/>

   <xsl:apply-templates mode='fs' select='exsl:node-set($content)' />
 </xsl:template>


 <!-- XXX: http://x namespace is so fucking descriptive -->


 <xsl:template match='x:form' mode='fs' xmlns:x='http://x'>
   <form xsl:use-attribute-sets='form'>
     <xsl:copy-of select='@*'/>
     <xsl:apply-templates mode='fs'/>
   </form>
 </xsl:template>


 <xsl:template match='x:input[@type="text" or @type="password" or
               not(@type)]' 
               mode='fs' xmlns:x='http://x'>
   <xsl:variable name='name' select='@name'/>
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


 <xsl:template match='x:select' 
               mode='fs' xmlns:x='http://x'>
   <xsl:element name='select'>
     <xsl:copy-of select='@*'/>
     <xsl:attribute name='class'>
       <xsl:choose>
         <xsl:when test='$form-errors//list-item=current()/@name'
         >edit highlight</xsl:when>
         <xsl:when test='not( @class )'>edit</xsl:when>
         <xsl:otherwise><xsl:value-of select='@class'/></xsl:otherwise>
       </xsl:choose>
     </xsl:attribute>
     <xsl:apply-templates mode='fs'/>

   </xsl:element>
 </xsl:template>


 <!-- checkbox -->

 <xsl:template match='x:input[@type="checkbox"]' mode='fs' xmlns:x='http://x'>
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
 <xsl:template match='x:input[@type="radio"]' mode='fs' xmlns:x='http://x'>
   <xsl:variable name='name' select='@name'/>
   <xsl:element name='input'>
     <xsl:copy-of select='@type|@id|@name|@value'/>

     <xsl:choose>

       <xsl:when test='not( $form-values/*[name()=$name] )
                 or $form-values/*[name()=$name]/undef'>

         <xsl:if test='@checked'>
           <xsl:attribute name='checked'>1</xsl:attribute>
         </xsl:if>

       </xsl:when>

       <xsl:otherwise>

         <xsl:if test='$form-values/*[name()=$name]/text() = @value'>
           <xsl:attribute name='checked'>1</xsl:attribute>
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
 <xsl:template match='x:input[@type="hidden"]' mode='fs' xmlns:x='http://x'>
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
 <xsl:template match='x:textarea' mode='fs' xmlns:x='http://x'>
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

 <xsl:template match='x:*' mode='fs' xmlns:x='http://x'>
   <xsl:element name='{local-name()}'>
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



 <!--  end of fieldset mode -->


  
</xsl:stylesheet>

