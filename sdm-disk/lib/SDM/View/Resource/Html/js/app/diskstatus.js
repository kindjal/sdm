
$(document).ready(function() {
  TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

  /* Top of page total summary */
  $.getJSON('/view/sdm/disk/volume/set/summary.json', function(result) {
    $("div#total").html(
      '<h2><a href="rrd.html?total">Cumulative Disk Usage</a></h2>'
      + '<h3>Disk usage added over all reporting NFS servers</h3>'
      + 'Total KB: ' + commify(result.total_kb) + " " + sizeSuffix( result.total_kb ) + '<br/>'
      + 'Used KB: ' + commify(result.used_kb) + " " + sizeSuffix( result.used_kb ) + '<br/>'
      + 'Percentage Consumed: ' + result.capacity.toFixed(0) + ' %<br/>'
      + 'Last Check: ' + result.last_modified + '<br/>'
    );
    $("div#total").addClass('emphasis');
  });
  /* end top */

  $('#filers').load("/view/sdm/disk/filer/set/table.html");
  $('#arrays').load("/view/sdm/disk/array/set/table.html");
  $('#group').load("/view/sdm/disk/volume/set/group.html");
  $('#volume').load("/view/sdm/disk/volume/set/table.html");

} ); /* end document ready function */
