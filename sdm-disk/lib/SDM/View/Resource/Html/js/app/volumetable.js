
/*
 *  This dataTables routine currently fills a table in a predefined way.
 *  it'd be nice to calculate number of columns and create the table on the fly.
 */

var dataTable;

$(document).ready(function() {
  TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

  /* data table */
  dataTable = $('#volumetable').dataTable( {
    "sDom": 'T<"clear">lfrtip',
    "bProcessing": true,
    "bFilter": true,
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    // "sAjaxSource": "/view/sdm/disk/volume/set/status.json",
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
          return parseFloat(oObj.aData[3]).toFixed(0) + " %";
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
  /* end data table */

} ); /* end document ready function */

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

