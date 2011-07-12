
function drawHostTable () {
    var aTable = $('#hosttable').dataTable( {
        "sDom": 'T<"clear">lfrtip',
        "bProcessing": true,
        "bServerSide": false,
        "sAjaxSource": "/view/sdm/disk/host/set/status.json",
        "iDisplayLength": 25,
        "sPaginationType": "full_numbers",
        "bAutoWidth": false,
        "aaSorting": [ [1,'desc'] ],
        "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
            $('td',nRow).each( function (iPosition) {
                var $cell = $(nRow).children('td').eq(iPosition);
                $cell.attr("title",aData[iPosition]);
            } );
            return nRow;
        },
        "aoColumns": [
            { "sTitle": "Hostname", "sWidth": "10%" },
            { "sTitle": "Filername", "sWidth": "15%"  },
            { "sTitle": "OS", "sWidth": "10%" },
            { "sTitle": "Location", "sWidth": "10%" },
            { "sTitle": "Status", "sWidth": "3%"  },
            { "sTitle": "Comments", "sWidth": "15%" },
            { "sTitle": "Created", "sWidth": "15%" },
            { "sTitle": "Last Modified", "sWidth": "12%" },
        ],
    } );
}

