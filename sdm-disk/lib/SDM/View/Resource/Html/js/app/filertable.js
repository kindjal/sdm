
$(document).ready(function() {
  TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

  /* data table */
  var fTable = $('#filertable').dataTable( {
    "sDom": 'T<"clear">lfrtip',
    "bProcessing": true,
    "iDisplayLength": 10,
    "sPaginationType": "full_numbers",
    "bAutoWidth": false,
    "aoColumns": [
      /* name       */ { "sWidth": "6%" },
      /* snmp_ok    */ { "sWidth": "5%", "sClass": "center"  },
      /* comments   */ { "sWidth": "20%"  },
      /* hosts      */ { "sWidth": "20%" },
      /* arrays     */ { "sWidth": "20%" },
      /* created    */ { "sWidth": "12%", "sClass": "center" },
      /* last check */ { "sWidth": "12%", "sClass": "center" },
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
    }

  } ); /* end dataTable */

} ); /* end document ready */
