
function drawHardwareTable () {
    var oTable;
    oTable = $('#hardwaretable').dataTable( {
            "sDom": 'T<"clear">lfrtip',
            "bProcessing": true,
            "bServerSide": false,
            "sAjaxSource": "/view/sdm/asset/hardware/set/table.json",
            "aoColumns": [
                { "sTitle": "id", "bVisible": false },
                { "sTitle": "manufacturer" },
                { "sTitle": "model" },
                { "sTitle": "serial" },
                { "sTitle": "description" },
                { "sTitle": "comments" },
                { "sTitle": "location" },
                { "sTitle": "created" },
                { "sTitle": "last_modified" },
            ],
    } ).makeEditable( {
        sUpdateURL: "/service/asset",
    } );
}
