
var hTable;
var gTable;
var vTable;

/* This is a data tables extension to reload Ajax Data */
$.fn.dataTableExt.oApi.fnReloadAjax = function ( oSettings, sNewSource, fnCallback, bStandingRedraw ) {
  if ( typeof sNewSource != 'undefined' && sNewSource != null )
  {
      oSettings.sAjaxSource = sNewSource;
  }
  this.oApi._fnProcessingDisplay( oSettings, true );
  var that = this;
  var iStart = oSettings._iDisplayStart;

  oSettings.fnServerData( oSettings.sAjaxSource, [], function(json) {
      /* Clear the old information from the table */
      that.oApi._fnClearTable( oSettings );

      /* Got the data - add it to the table */
      for ( var i=0 ; i<json.aaData.length ; i++ )
      {
          that.oApi._fnAddData( oSettings, json.aaData[i] );
      }

      oSettings.aiDisplay = oSettings.aiDisplayMaster.slice();
      that.fnDraw( that );

      if ( typeof bStandingRedraw != 'undefined' && bStandingRedraw === true )
      {
          oSettings._iDisplayStart = iStart;
          that.fnDraw( false );
      }

      that.oApi._fnProcessingDisplay( oSettings, false );

      /* Callback user function - for event handlers etc */
      if ( typeof fnCallback == 'function' && fnCallback != null )
      {
          fnCallback( oSettings );
      }
  } );
} /* end fnReloadAjax */

$(document).ready(function() {
  TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

  /* Top of page total summary */
  $.getJSON('/view/sdm/disk/volume/set/summary.json', function(result) {
    $("div#total").html(
      '<h2><a href="rrd.html?total">Cumulative Disk Usage</a></h2>'
      + '<h3>Disk usage added over all reporting NFS servers</h3>'
      + 'Total KB: ' + commify(result.total_kb) + " " + sizeSuffix( result.total_kb ) + '<br/>'
      + 'Used KB: ' + commify(result.used_kb) + " " + sizeSuffix( result.used_kb ) + '<br/>'
      + 'Percentage Consumed: ' + result.capacity.toFixed(0) + ' %<br/>'
      + 'Last Check: ' + result.last_modified + '<br/>'
    );
    $("div#total").addClass('emphasis');
  });
  /* end top */

  /* filers table */
  hTable = $('#filers').dataTable( {
    "bProcessing": true,
    "bServerSide": false,
    "iDisplayLength": 10,
    "sPaginationType": "full_numbers",
    "bAutoWidth": false,
    "sAjaxSource": "/view/sdm/disk/filer/set/status.json",
    "aoColumns": [
      /* name       */ { "sWidth": "15%" },
      /* snmp_ok    */ { "sWidth": "5%"  },
      /* hosts      */ { "sWidth": "20%" },
      /* arrays     */ { "sWidth": "20%" },
      /* added      */ { "sWidth": "20%", "sClass" : "center" },
      /* last check */ { "sWidth": "20%", "sClass" : "center" },
    ],
    "aaSorting": [ [1,'asc'] ],
    "fnRowCallback": function( nRow, aaData, iDisplayIndex ) {
      /* Set class for color on column 0 */
      var $cell = $(nRow).children('td').eq(0);
      if (aaData[1] == -1) {
        $cell.addClass('warning');
      }
      if (aaData[1] == 0) {
        $cell.addClass('notice');
      }
      /* Set title of columns 2 and 3 */
      var title = aaData[2];
      var $cell = $(nRow).children('td').eq(2);
      $cell.attr("title",title);

      var title = aaData[3];
      var $cell = $(nRow).children('td').eq(3);
      $cell.attr("title",title);

      return nRow;
    },
  } );
  /* end filer table */

  /* summary by disk group table */
  gTable = $('#group').dataTable( {
    "sDom": 'T<"clear">lfrtip',
    "bProcessing": true,
    "bServerSide": false,
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    "sAjaxSource": "/view/sdm/disk/volume/set/group.json",
    "aaSorting": [ [1,'desc'] ],
    "aoColumns": [
      /* disk group column */
      null,
      /* total_kb column */
      { "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[1] ) + " " + sizeSuffix( oObj.aData[1] );
         },
      },
      /* used_kb column */
      { "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[2] ) + " " + sizeSuffix( oObj.aData[2] );
        },
      },
      /* capacity column */
      { "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.aData[3].toFixed(0) + " %";
        },
      }
    ],
    "fnRowCallback": function( nRow, aaData, iDisplayIndex )
    {
      /* make disk group an href */
      // <a href=\"rrd.html?$a[0]\">$a[0]</a>
      var $col = 0;
      var $cell = $(nRow).children('td').eq($col);
      $('td:eq(0)', nRow).html( "<a href=\"rrd.html?" + aaData[0] + "\">" + aaData[0] + "</a>" );

      /* append a css color class based on cell content */
      /* capacity > 95 */
      var $col = 3;
      var $cell = $(nRow).children('td').eq($col);
      if ( aaData[$col] > 95 )
      {
        $cell.addClass('warning');
      }
      /* group is 'unknown' */
      var $col = 0;
      var $cell = $(nRow).children('td').eq($col);
      if ( aaData[$col] == 'unknown' )
      {
        $cell.addClass('warning');
      }

      return nRow;
    }
  } );
  /* end summary by disk group*/

  /* volume table */
  vTable = $('#volume').dataTable( {
    "sDom": 'T<"clear">lfrtip',
    "bProcessing": true,
    "bFilter": true,
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    "sAjaxSource": "/view/sdm/disk/volume/set/status.json",
    /* Sort by Total KB column by default */
    "aaSorting": [ [1,'desc'] ],
    "aoColumns": [
      null,
      /* total_kb column */
      { "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[1] ) + " " + sizeSuffix( oObj.aData[1] );
        },
      },
      /* used_kb column */
      { "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[2] ) + " " + sizeSuffix( oObj.aData[2] );
        },
      },
      /* capacity column */
      { "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.aData[3].toFixed(0) + " %";
        },
      },
      null,
      null,
      null,
    ],
    "fnRowCallback": function( nRow, aaData, iDisplayIndex )
    {
        /* append a css class based on cell content */
        /* capacity > 95 is column 3*/
        var $col = 3;
        var $cell = $(nRow).children('td').eq($col);
        if ( aaData[$col] > 95 )
        {
          $cell.addClass('warning');
        }
        /* group is 'unknown' is column 4 */
        var $col = 4;
        var $cell = $(nRow).children('td').eq($col);
        if ( aaData[$col] == 'unknown' )
        {
          $cell.addClass('warning');
        }
        return nRow;
    },
  } );
  /* end volume summary table */

  /* take a big number of KB and make it pretty: 1,000 => (1 MB) */
  function sizeSuffix ( n ) {
    var size = String(n).length
    var units
    var divisor
    switch(true) {
      case size < 4:
          units = 'KB'
          divisor = 1
          break
      case (size >= 4 && size < 7):
          units = 'MB'
          divisor = 1000
          break
      case (size >= 7 && size < 10):
          units = 'GB'
          divisor = 1000000
          break
      case (size >= 10 && size < 13):
          units = 'TB'
          divisor = 1000000000
          break
      case (size >= 13 && size < 16):
          units = 'PB'
          divisor = 1000000000000
          break
      case (size >= 16 && size < 19):
          units = 'EB'
          divisor = 1000000000000000
          break
    }
    var shortVal = n / divisor
    return "(" + String( shortVal.toFixed(0) ) + " " + units + ")"
  };

  /* Add commas to a number */
  function commify(n) {
    nStr = String(n)
    x = nStr.split('.')
    x1 = x[0]
    x2 = x.length > 1 ? '.' + x[1] : ''
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
      x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
  };

} ); /* end document ready function */
