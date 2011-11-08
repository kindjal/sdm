
function drawHardwareTable () {
    oTable = $('#hardwaretable').dataTable( {
            "sDom": 'T<"clear">lfrtip',
            "bProcessing": true,
            "bServerSide": false,
            //"iDisplayLength": 25,
            //"sPaginationType": "full_numbers",
            "sAjaxSource": "/view/sdm/asset/hardware/set/table.json",
            /*"fnServerData": function( sUrl, aoData, fnCallback ) {
              $.ajax( {
                 "url": sUrl,
                 "data": aoData,
                 "success": fnCallback,
                 "dataType": "json",
                 "cache": false
              } );
            },*/
            //"aaSorting": [ [1,'desc'] ],
            "aoColumns": [
            { "sTitle": "Make", },
            { "sTitle": "Model", },
            { "sTitle": "serial", },
            { "sTitle": "created", },
            { "sTitle": "modified", },
            ],
            /*
               "fnRowCallback": function( nRow, aaData, iDisplayIndex ) {
               var $col = 0;
               var $cell = $(nRow).children('td').eq($col);
               $('td:eq(0)', nRow).html( "<a href=\"/view/sdm/rrd.html?" + aaData[0] + "\">" + aaData[0] + "</a>" );
               var $col = 3;
               var $cell = $(nRow).children('td').eq($col);
               if ( aaData[$col] > 95 ) {
               $cell.addClass('warning');
               }

               return nRow;
               }
               */
    } ).makeEditable( {
        sUpdateURL: "/service/asset",
        ajaxoptions:{ type: 'GET' }
        //sUpdateURL: function(value, settings) { }
    } );
}

        //sDeleteURL: "/service/asset/delete.pl",
        //sAddURL:    "/service/asset/add.pl",
