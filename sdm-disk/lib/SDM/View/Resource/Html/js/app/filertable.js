
/*
 *  This dataTables routine currently fills a table in a predefined way.
 *  it'd be nice to calculate number of columns and create the table on the fly.
 */

var dataTable;

$(document).ready(function() {
  TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

  /* data table */
  dataTable = $('#filertable').dataTable( {
    "sDom": 'T<"clear">lfrtip',
    "bProcessing": true,
    "bFilter": true,
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    "aaSorting": [ [1,'desc'] ],
  } );
  /* end data table */

} ); /* end document ready function */

