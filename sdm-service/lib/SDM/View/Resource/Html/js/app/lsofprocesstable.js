
var oTable;

$(document).ready(function() {
    TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

    var oTable = $('#lsofprocesstable').dataTable( {
        "sDom": 'T<"clear">lfrtip',
        //"bProcessing": false,
        //"bFilter": false,
        //"bServerSide": false,
        "iDisplayLength": 25,
        "sPaginationType": "full_numbers",
        /* use json and includea  reload-every function in the table for periodic reloading */
        //"sAjaxSource": "/view/sdm/service/lsof/process/set/status.json",
        /* Sort by Total KB column by default */
        "aaSorting": [ [1,'desc'] ],
        "aoColumns": [ 
        { "sWidth": "12%" },
        { "sWidth": "5%" },
        { "sWidth": "5%" },
        { "sWidth": "5%" },
        { "sWidth": "5%" },
        { "sWidth": "10%" },
        { "sWidth": "10%" },
        { "sWidth": "20%" },
        { "sWidth": "11%" },
        { "sWidth": "11%" },
        ],
        "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
            $('td',nRow).each( function (iPosition) {
                if (this.title) {
                    $('td:eq(' + iPosition + ')',nRow).html( this.title );
                }
            } );
            return nRow;
        },
    } );
    /* end data table */

} ); /* end document ready function */

