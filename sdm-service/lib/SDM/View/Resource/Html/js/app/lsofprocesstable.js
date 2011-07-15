
function drawLsofProcessTable () {
    var oTable = $('#lsofprocesstable').dataTable( {
        "sDom": 'T<"clear">lfrtip',
        "bProcessing": true,
        "bServerSide": false,
        "iDisplayLength": 25,
        "sPaginationType": "full_numbers",
        "sAjaxSource": "/view/sdm/service/lsof/process/set/status.json",
        "aaSorting": [ [1,'desc'] ],
        "aoColumns": [ 
        { "sTitle": "Hostname", "sWidth": "12%" },
        { "sTitle": "PID", "sWidth": "5%" },
        { "sTitle": "Command", "sWidth": "5%" },
        { "sTitle": "Username", "sWidth": "5%" },
        { "sTitle": "UID", "sWidth": "5%" },
        { "sTitle": "Age", "sWidth": "5%" },
        { "sTitle": "Nfsd", "sWidth": "5%" },
        { "sTitle": "Filename", "sWidth": "20%" },
        { "sTitle": "Created", "sWidth": "11%" },
        { "sTitle": "Last Modified", "sWidth": "11%" },
        ],
        "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
            $('td',nRow).each( function (iPosition) {
                var $cell = $(nRow).children('td').eq(iPosition);
                $cell.attr("title",aData[iPosition]);
            } );
            return nRow;
        },
    } );
}

