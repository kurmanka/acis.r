<xsl:stylesheet
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:exsl="http://exslt.org/common"
 exclude-result-prefixes='exsl'
 version="1.0">

  <xsl:variable name='map' select='document("../tmp/index-3.xml")'/>

  <xsl:template match='/'>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:param name='date'/>

  <xsl:template match='text[@file]'>
    <xsl:document href='{@file}'
                  method='html'>
      <html>
        <head>
          <title><xsl:apply-templates select='h1' mode='text'/> / ACIS documentation</title>
          <link rel='stylesheet' href='style.css'/>
          <xsl:if test='.//style'>
            <style type='text/css'>
<xsl:copy-of select='.//style/text()'/>
            </style>
          </xsl:if>
            
        </head>
        <body>
          <xsl:apply-templates/>

          <address class='footer'>
            
            <xsl:apply-templates mode='footer'/>

            <xsl:if test='$date'>
              <p><xsl:text>Generated: </xsl:text>
              <xsl:value-of select='$date'/></p>
            </xsl:if>
            <p><a href='http://acis.openlib.org/'>ACIS project</a>,
          acis<i>@</i>openlib<span>.org</span>
  
            </p>
          </address>

        </body>
      </html>
    </xsl:document>
  </xsl:template>


  <xsl:template match='C'>
    <code class='C'>
      <xsl:apply-templates/>
    </code>
  </xsl:template>

  <xsl:template match='F'>
    <code class='F'>
      <xsl:apply-templates/>
    </code>
  </xsl:template>

  <xsl:template match='co'>
    <code>
      <xsl:copy-of select='@*'/>
      <xsl:apply-templates/>
    </code>
  </xsl:template>


  <xsl:template match='c|f|a[not(@ref) and not(@href)]'>
    <xsl:variable name='name'>
      <xsl:apply-templates mode='text'/>
    </xsl:variable>
    <xsl:variable name='item' select='exsl:node-set($map)/index/item[@name=$name or @id=$name]'/>

    <xsl:choose>
      <xsl:when test='$item'>
        <xsl:variable name='file' select='$item/@file'/>
        <a class='{name()}' href='{$file}#{$item/@id}'><xsl:apply-templates/></a>
      </xsl:when>

      <xsl:otherwise>
        <xsl:if test='name()="a" or name()="c"'>
          <xsl:message>Broken link to <xsl:value-of select='$name'/></xsl:message>
        </xsl:if>
        <code class='{name()} BROKEN'>
          <xsl:apply-templates/>
        </code>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match='a[@ref]'>
    <xsl:variable name='name'>
      <xsl:value-of select='@ref'/>
    </xsl:variable>

    <xsl:variable name='item'
      select='exsl:node-set($map)/index/item[@id=$name or @name=$name]'/>
      
    <xsl:variable name='file'
                  select='$item/@file'/>

    <a href='{$file}#{$item/@id}'>
      <xsl:copy-of select='class|title'/>
      <xsl:apply-templates/>
    </a>
  </xsl:template>


  <xsl:template match='*'>
    <xsl:copy>
      <xsl:copy-of select='@*'/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>


  <xsl:template mode='text' match='text()'>
    <xsl:copy/>
  </xsl:template>

  <xsl:template mode='text' match='*'>
    <xsl:apply-templates/>
  </xsl:template>
 
  <xsl:template match='p[style]'/>


  <xsl:template name='toc' match='p[toc]'>

    <h3><i>Table of contents</i></h3>

    <p class='toc'>
      <xsl:apply-templates select='ancestor::text' mode='toc'/>
    </p>

  </xsl:template>

  <xsl:template match='*' mode='toc'>
    <xsl:apply-templates mode='toc'/>
  </xsl:template>

  <xsl:template match='text()' mode='toc'/>
  
  <xsl:template match='h2|h3|h4' mode='toc'>

    <xsl:if test='name() = "h3" or name() = "h4"'>
      <xsl:text>&#160;</xsl:text>
      <xsl:text>&#160;</xsl:text>
      <xsl:text>&#160;</xsl:text>
    </xsl:if>

    <xsl:if test='name() = "h4"'>
      <xsl:text>&#160;</xsl:text>
      <xsl:text>&#160;</xsl:text>
      <xsl:text>&#160;</xsl:text>
    </xsl:if>

    <xsl:variable name='id' select='@id'/>
    <xsl:variable name='text' select='ancestor::text'/>

<!--
    <xsl:if test='name() = "h2" and preceding::h2[ancestor::text = $text] '>
      <br/>
    </xsl:if>
-->

<xsl:text>&#160;</xsl:text>
<xsl:text>&#160;</xsl:text>
<xsl:text>&#160;</xsl:text>

    <a href='#{@id}'>
      <xsl:apply-templates/>
    </a>
    <br/>


  </xsl:template>


  <xsl:template match='foot|id'/>

  <xsl:template match='text()' mode='footer'/>
 
  <xsl:template match='*' mode='footer'>
    <xsl:apply-templates mode='footer'/>
  </xsl:template>

  <xsl:template match='foot' mode='footer'>
    <div class='footer'>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match='id' mode='footer'>
    <p>
      <xsl:copy-of select='text()'/>
    </p>
  </xsl:template>
 

</xsl:stylesheet>