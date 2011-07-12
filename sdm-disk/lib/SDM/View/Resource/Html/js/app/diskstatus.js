
$(document).ready(function() {
  TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";

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

  drawFilerTable();
  drawArrayTable();
  drawGroupTable();
  drawVolumeTable();

} );
