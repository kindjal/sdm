
$(document).ready(function() {
  TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

  /* data table */
  var dataTable = $('#arraytable').dataTable( {
    "sDom": 'T<"clear">lfrtip',
    "bProcessing": true,
    "bFilter": true,
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    "aaSorting": [ [1,'desc'] ],
    "aoColumns": [
      null,
      null,
      null,
      null,
      null,
      null,
      { "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[6] ) + " " + sizeSuffix( oObj.aData[6] );
        },
      },
      { "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[7] ) + " " + sizeSuffix( oObj.aData[7] );
        },
      },
      null,
      null,
      null,
    ],
  } );
  /* end data table */

} ); /* end document ready function */

