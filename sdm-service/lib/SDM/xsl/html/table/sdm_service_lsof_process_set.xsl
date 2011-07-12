<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:attribute-set name="table-cell-attrs">
  <xsl:attribute name="title">
    <xsl:value-of select='value'/>
  </xsl:attribute>
</xsl:attribute-set>

<xsl:template name="sdm_service_lsof_process_set" match="/object[@type='SDM::Service::Lsof::Process::Set']">
  <xsl:comment>template: /html/table/sdm_service_lsof_process_set.xsl match="object[@type='SDM::Service::Lsof::Process::Set']"</xsl:comment>

  <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <!-- Disable browser caching -->
    <meta http-equiv='Pragma' content='no-cache'/>
    <!-- Microsoft browsers require this additional meta tag as well -->
    <meta http-equiv='Expires' content='-1'/>

    <title>SDM::Service::Lsof::Process::Set</title>
    <style type="text/css" title="currentStyle">
      @import "/res/css/diskstatus_page.css";
      @import "/res/css/diskstatus_table.css";
      @import "/res/js/pkg/TableTools/media/css/TableTools.css";
    </style>
    <link rel="shortcut icon" href="/res/img/gc_favicon.png" />
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/jQuery/jquery.min.js"/>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/DataTables/media/js/jquery.dataTables.js"/>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/TableTools/media/ZeroClipboard/ZeroClipboard.js"/>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/TableTools/media/js/TableTools.js"/>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/jquery.timers.js"/>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/app/common.js"/>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/app/lsofprocesstable.js"/>
    </head>

    <body id="dt_example">
    <div id="container">
      <table width="100%" cellspacing="0" cellpadding="0" border="0" id="lsofprocesstable" class="display">
      </table>
    </div>
    </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
