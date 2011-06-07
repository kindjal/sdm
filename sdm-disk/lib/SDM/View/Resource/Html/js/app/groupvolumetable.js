
$(document).ready(function() {
  TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

  $('#group').dataTable( {
    "sDom": 'T<"clear">lfrtip',
    "bProcessing": true,
    "bServerSide": false,
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    "sAjaxSource": "/view/sdm/disk/volume/set/group.json",
    "aaSorting": [ [1,'desc'] ],
    "aoColumns": [
      /* disk group column */
      { "sWidth": "20%" },
      /* total_kb column */
      { "sWidth": "20%",
        "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[1] ) + " " + sizeSuffix( oObj.aData[1] );
         },
      },
      /* used_kb column */
      { "sWidth": "20%",
        "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[2] ) + " " + sizeSuffix( oObj.aData[2] );
        },
      },
      /* capacity column */
      { "sWidth": "5%",
        "sType": "numeric",
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
      $('td:eq(0)', nRow).html( "<a href=\"/view/sdm/rrd.html?" + aaData[0] + "\">" + aaData[0] + "</a>" );

      /* append a css color class based on cell content */
      /* capacity > 95 */
      var $col = 3;
      var $cell = $(nRow).children('td').eq($col);
      if ( aaData[$col] > 95 ) {
        $cell.addClass('warning');
      }

      return nRow;
    }
  } );

} ); /* end document ready function */

