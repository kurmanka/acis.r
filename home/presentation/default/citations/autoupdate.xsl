<!--   This file is part of the ACIS presentation template-set.   -->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  exclude-result-prefixes='exsl'
  version="1.0">  

  <xsl:import href='general.xsl'/>
  <xsl:import href='../yes-no-choice.xsl'/>

  <xsl:variable name='current-screen-id'>citations/autoupdate</xsl:variable>


  <xsl:template match='/data'>
    <xsl:call-template name='cit-page'>

      <xsl:with-param name='title'>automatic citations update preferences</xsl:with-param>

      <xsl:with-param name='content'>

<h1>Automatic citation profile update</h1>

    <xsl:call-template name='show-status'/>

     <xsl:call-template name='fieldset'>
       <xsl:with-param name='content' xmlns='http://x'>

<form screen='@citations/autoupdate'
      class='important' name='f'> 
 
<phrase ref='citations-autoupdate-intro'>
 <p>We can do automatic additions to your citation profile
  in certain cases (explained below).  An email
  notification will be sent to you every time we change
  your profile automatically.  Here you may disable or
  enable automatic changes to your profile.</p>
</phrase>


<h2>Preferences</h2>

  <p><strong>Q1.</strong> 
  When we know with high certainty that a new citation is
  pointing to one of your works, should we automatically
  add it to your identified citations? (You can always fix
  it later, if a mistake happens.)</p>

  <p class='pad'>
    <xsl:call-template name='yes-no-choice'>
      <xsl:with-param name='param-name'>auto-identified-auto-add</xsl:with-param>
      <xsl:with-param name='default' select='"yes"'/>
    </xsl:call-template>
  </p>

  <p><strong>Q2.</strong> 
  When one of your co-authors has identified a citation as
  pointing to your co-authored document, should we add
  it to your profile also?
  </p>

  <p class='pad'>
    <xsl:call-template name='yes-no-choice'>
      <xsl:with-param name='param-name'>co-auth-auto-add</xsl:with-param>
      <xsl:with-param name='default' select='"yes"'/>
    </xsl:call-template>
  </p>

  <p><input type='submit' class='important' value=' SAVE '/></p>


  <phrase ref='citations-autoupdate-notification-mails-note'>
  <p>The notification messages will be sent from address:</p>

  <p class='pad'><tt><xsl:value-of select='$system-email'/></tt></p>

  <p>Please add this address to your spam filter's whitelist
  to make sure it does not stop these messages.</p>
  </phrase>

</form>       

     </xsl:with-param>
</xsl:call-template>


      </xsl:with-param>

    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>