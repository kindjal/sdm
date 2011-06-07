
$(document).ready(function() {
  TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

  /* data table */
  var aTable = $('#arraytable').dataTable( {
    "sDom": 'T<"clear">lfrtip',
    "bProcessing": true,
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    "bAutoWidth": false,
    "aaSorting": [ [1,'desc'] ],
    "aoColumns": [
      { "sWidth": "10%" },
      { "sWidth": "6%" },
      { "sWidth": "10%" },
      { "sWidth": "10%" },
      { "sWidth": "5%" },
      { "sWidth": "5%" },
      { "sWidth": "12%",
        "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[6] ) + " " + sizeSuffix( oObj.aData[6] );
        },
      },
      { "sWidth": "12%",
        "sType": "numeric",
        "bUseRendered": false,
        "fnRender": function ( oObj ) {
          return oObj.oSettings.fnFormatNumber( oObj.aData[7] ) + " " + sizeSuffix( oObj.aData[7] );
        },
      },
      { "sWidth": "12%" },
      { "sWidth": "12%" },
      { "sWidth": "6%" },
    ],
  } );
  /* end data table */

} ); /* end document ready function */

