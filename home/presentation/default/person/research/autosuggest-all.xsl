<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href='autosuggest-chunk.xsl' />

  <xsl:variable name='form-target'>@research/autosuggest-all</xsl:variable>

  <xsl:variable name='screen-autosuggest-all' select='true()'/>

  <xsl:variable name='chunk-size' select='$suggestions-count'/>

   
</xsl:stylesheet>

