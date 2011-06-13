
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
      { "sWidth": "6%"  },
      { "sWidth": "10%" },
      { "sWidth": "10%" },
      { "sWidth": "6%"  },
      { "sWidth": "12%" },
      { "sWidth": "12%" },
      { "sWidth": "12%" }
    ],
  } );
  /* end data table */

} ); /* end document ready function */

