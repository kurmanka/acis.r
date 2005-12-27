<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">

  <xsl:import href='page.xsl'/>

  <xsl:variable name='current-screen-id'>personal-photo</xsl:variable>

  <xsl:template match='/data'>
    <xsl:call-template name='user-page'>
      <xsl:with-param name='title'>photo upload</xsl:with-param>
   <xsl:with-param name='content' xml:space='preserve'>

     <h1>Photo</h1>
     
    <xsl:call-template name='show-status'/>

    <form xsl:use-attribute-sets='form' enctype='multipart/form-data'>

      <xsl:if test='$response-data/photo/text()'>
        <img src='{$response-data/photo/text()}' class='photo'/>
      </xsl:if>

      <h2>upload<xsl:if test='$response-data/photo'> new</xsl:if></h2>

     <p>
      <label for='photo' class='form-field'>File of the photo (GIF or JPEG):</label><br/>
      <input type='file' name='photo' id='photo'/></p>

      <p> </p>

      <p>
        <input type='submit' value='continue' class='important'/>
      </p>
    </form>

    <p><a ref='@menu'>Return to main menu.</a></p>

   </xsl:with-param>
  </xsl:call-template>
 </xsl:template>

</xsl:stylesheet>
