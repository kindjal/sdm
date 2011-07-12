
function drawVolumeTable () {
    $('#volumetable').dataTable( {
        "sDom": 'T<"clear">lfrtip',
        "bProcessing": true,
        "bServerSide": false,
        "sAjaxSource": "/view/sdm/disk/volume/set/status.json",
        "bFilter": true,
        "iDisplayLength": 25,
        "sPaginationType": "full_numbers",
        /* Sort by Total KB column by default */
        "aaSorting": [ [1,'desc'] ],
        "aoColumns": [
            { "sTitle": "Mount Path" },
            { "sTitle": "Total KB",
              "sType": "numeric",
              "bUseRendered": false,
              "fnRender": function ( oObj ) {
                return oObj.oSettings.fnFormatNumber( oObj.aData[1] ) + " " + sizeSuffix( oObj.aData[1] );
              },
            },
            { "sTitle": "Used KB",
              "sType": "numeric",
              "bUseRendered": false,
              "fnRender": function ( oObj ) {
                return oObj.oSettings.fnFormatNumber( oObj.aData[2] ) + " " + sizeSuffix( oObj.aData[2] );
              },
            },
            { "sTitle": "Capacity",
              "sType": "numeric",
              "bUseRendered": false,
              "fnRender": function ( oObj ) {
                return parseFloat(oObj.aData[3]).toFixed(0) + " %";
              },
            },
            { "sTitle": "Disk Group" },
            { "sTitle": "Filername" },
            { "sTitle": "Last Modified" },
        ],
        "fnRowCallback": function( nRow, aaData, iDisplayIndex )
        {
            /* append a css class based on cell content */
            /* capacity > 95 is column 3*/
            var $col = 3;
            var $cell = $(nRow).children('td').eq($col);
            if ( aaData[$col] > 95 )
            {
              $cell.addClass('warning');
            }
            /* group is 'unknown' is column 4 */
            var $col = 4;
            var $cell = $(nRow).children('td').eq($col);
            if ( aaData[$col] == 'unknown' )
            {
              $cell.addClass('warning');
            }
            return nRow;
        },
    } );
}
