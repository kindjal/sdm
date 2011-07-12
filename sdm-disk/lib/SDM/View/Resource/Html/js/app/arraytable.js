
function drawArrayTable () {
    var aTable = $('#arraytable').dataTable( {
        "sDom": 'T<"clear">lfrtip',
        "bProcessing": true,
        "bServerSide": false,
        "sAjaxSource": "/view/sdm/disk/array/set/status.json",
        "iDisplayLength": 25,
        "sPaginationType": "full_numbers",
        "bAutoWidth": false,
        "aaSorting": [ [1,'desc'] ],
        "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
            $('td',nRow).each( function (iPosition) {
                if (this.title) {
                    $('td:eq(' + iPosition + ')',nRow).html( this.title );
                }
            } );
            return nRow;
        },
        "aoColumns": [
            { "sTitle": "Array", "sWidth": "10%" },
            { "sTitle": "Manufacturer", "sWidth": "6%"  },
            { "sTitle": "Model", "sWidth": "10%" },
            { "sTitle": "Serial", "sWidth": "10%" },
            { "sTitle": "Hostname", "sWidth": "6%"  },
            { "sTitle": "Array Size",
              "sWidth": "12%",
              "sType": "numeric",
              "bUseRendered": false,
              "fnRender": function ( oObj ) {
                return oObj.oSettings.fnFormatNumber( oObj.aData[5] ) + " " + sizeSuffix( oObj.aData[5] );
              },
            },
            { "sTitle": "Created", "sWidth": "12%" },
            { "sTitle": "Last Modified", "sWidth": "12%" }
        ],
    } );
}
