<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="sdm_disk_volume_set" match="/object[@type='SDM::Disk::Volume::Set']">
  <xsl:comment>template: /html/table/sdm_disk_volume_set.xsl match="object[@type='SDM::Disk::Volume::Set']"</xsl:comment>

  <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <!-- Disable browser caching -->
    <meta http-equiv='Pragma' content='no-cache'/>
    <!-- Microsoft browsers require this additional meta tag as well -->
    <meta http-equiv='Expires' content='-1'/>

    <title>SDM::Disk::Volume::Set</title>
    <style type="text/css" title="currentStyle">
      @import "/res/css/diskusage_page.css";
      @import "/res/css/diskusage_table.css";
      @import "/res/js/pkg/TableTools/media/css/TableTools.css";
    </style>
    <link rel="shortcut icon" href="/res/img/gc_favicon.png" />
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/jQuery/jquery.min.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/DataTables/media/js/jquery.dataTables.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/TableTools/media/ZeroClipboard/ZeroClipboard.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/TableTools/media/js/TableTools.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/app/common.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/app/volumetable.js"></script>
    </head>

    <body id="dt_example">
    <div id="container">
      <table width="100%" cellspacing="0" cellpadding="0" border="0" id="volumetable" class="display">
        <thead>
          <tr>
            <xsl:for-each select="/object/aspect[@name='members']/object[1]/aspect">
            <th> <xsl:value-of select="@name"/> </th>
            </xsl:for-each>
          </tr>
        </thead>
        <tbody>
          <xsl:for-each select="/object/aspect[@name='members']/object">
            <tr>
            <xsl:for-each select="aspect">
              <td> <xsl:value-of select="value"/> </td>
            </xsl:for-each>
            </tr>
          </xsl:for-each>
        </tbody>
      </table>
    </div> <!-- end div container -->
    </body> <!-- end body -->
    </html>

  </xsl:template>
</xsl:stylesheet>
