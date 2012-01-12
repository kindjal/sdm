
function drawFilerTable () {
    var fTable = $('#filertable').dataTable( {
        "sDom": 'T<"clear">lfrtip',
        "bProcessing": true,
        "bServerSide": false,
        "sAjaxSource": "/view/sdm/disk/filer/set/status.json",
        "iDisplayLength": 10,
        "sPaginationType": "full_numbers",
        "bAutoWidth": false,
        // These columns must match the columns returned by sAjaxSource
        "aoColumns": [
            { "sWidth": "6%",  "sTitle": "id", "bVisible": false },
            { "sWidth": "6%",  "sTitle": "name" },
            { "sWidth": "5%",  "sTitle": "status", "sClass": "center"  },
            { "sWidth": "5%",  "sTitle": "type", "sClass": "center"  },
            { "sWidth": "10%", "sTitle": "master"  },
            { "sWidth": "12%", "sTitle": "hosts" },
            { "sWidth": "12%", "sTitle": "arrays" },
            { "sWidth": "10%", "sTitle": "comments"  },
            { "sWidth": "12%", "sTitle": "created", "sClass": "center" },
            { "sWidth": "12%", "sTitle": "last_modified", "sClass": "center" },
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
    } ).makeEditable( {
                         sUpdateURL: "/service/update?class=Sdm::Disk::Filer",
                         sAddURL: "/service/add?class=Sdm::Disk::Filer",
                         sDeleteURL: "/service/delete?class=Sdm::Disk::Filer",
                         // Set editable columns with {}, non-editable with null
                         // These columns must match the list of bVisbile columns
                         // from aoColumns above, in the dataTable() declaration.
                         "aoColumns": [
                         {},
                         null,
                         {},
                         null,
                         null,
                         null,
                         {},
                         null,
                         null
                         ]
     } );
}
