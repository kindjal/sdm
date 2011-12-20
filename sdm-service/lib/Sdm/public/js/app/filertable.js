
function drawFilerTable () {
    var fTable = $('#filertable').dataTable( {
        "sDom": 'T<"clear">lfrtip',
        "bProcessing": true,
        "bServerSide": false,
        "sAjaxSource": "/view/sdm/disk/filer/set/status.json",
        "iDisplayLength": 10,
        "sPaginationType": "full_numbers",
        "bAutoWidth": false,
        "aoColumns": [
            { "sWidth": "6%",  "sTitle": "Name" },
            { "sWidth": "5%",  "sTitle": "Status", "sClass": "center"  },
            { "sWidth": "12%", "sTitle": "Hosts" },
            { "sWidth": "12%", "sTitle": "Arrays" },
            { "sWidth": "10%", "sTitle": "Comments"  },
            { "sWidth": "12%", "sTitle": "Created", "sClass": "center" },
            { "sWidth": "12%", "sTitle": "Last Checked", "sClass": "center" },
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
    } );
}
