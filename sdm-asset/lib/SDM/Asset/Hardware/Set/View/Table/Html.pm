
package SDM::Asset::Hardware::Set::View::Table::Html;

use strict;
use warnings;

use SDM;

class SDM::Asset::Hardware::Set::View::Table::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;

    # Determine attributes of class for columns of the table
    my $class = $self->subject_class_name;

    # We assume there is a corresponding Json.pm class next to this Html.pm class.
    my $jsonpath = lc $class;
    $jsonpath =~ s/::/\//g;
    $jsonpath = "/view/${jsonpath}/table.json";

    $class =~ s/::Set//g;

    my @properties = $class->__meta__->properties;
    my @attributes = map { $_->property_name } @properties;
    my @attributes = sort @attributes;
    # id must be the first attribute
    @attributes = grep { ! /id/ } @attributes;
    unshift @attributes,'id';

    # Here's the javascript datatable for the class attributes.
    my $tablescript =<<EOF;
    <script type="text/javascript" language="javascript" charset="utf-8">
        function drawTable () {
            var oTable;
            oTable = \$('#datatable').dataTable( {
                    "sDom": 'T<"clear">lfrtip',
                    "bProcessing": true,
                    "bServerSide": false,
                    "sAjaxSource": "$jsonpath",
                    "aoColumns": [
EOF
    foreach my $attr (sort @attributes) {
        $tablescript .= qq/{ "sTitle": "$attr" },\n/;
    }
    $tablescript .= <<EOF;
                    ],
                    } ).makeEditable( {
                        sUpdateURL: "/service/asset",
            } );
        }
    </script>
EOF
                        #sUpdateURL: "/service/asset/hardware/update",

    # Here's the rest of the HTML document
    my $content;
    while (my $line = <DATA>) {
        if ($line =~ /<%= tablescript %>/) {
            $content .= $tablescript;
        } else {
            $content .= $line;
        }
    }

    return $content;
}

1;
__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">·
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <!-- Disable browser caching -->
    <meta http-equiv='Pragma' content='no-cache'/>
    <!-- Microsoft browsers require this additional meta tag as well -->
    <meta http-equiv='Expires' content='-1'/>
    <title>SDM::Disk::Volume::Set</title>
    <style type="text/css" title="currentStyle">
      @import "/res/css/diskstatus_page.css";
      @import "/res/css/diskstatus_table.css";
      @import "/res/js/pkg/TableTools/media/css/TableTools.css";
    </style>
    <link rel="shortcut icon" href="/res/img/gc_favicon.png" />
    <!-- <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/jQuery/jquery.min.js"></script> -->
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/jquery.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/DataTables/media/js/jquery.dataTables.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/TableTools/media/ZeroClipboard/ZeroClipboard.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/TableTools/media/js/TableTools.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/jquery-datatables-editable/jquery-ui.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/jquery-datatables-editable/jquery.jeditable.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/jquery-datatables-editable/jquery.validate.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/pkg/jquery-datatables-editable/jquery.dataTables.editable.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/res/js/app/common.js"></script>
    <%= tablescript %>
    <script type="text/javascript" language="javascript" charset="utf-8">
$(document).ready(function() {
TableToolsInit.sSwfPath = "/res/js/pkg/TableTools/media/swf/ZeroClipboard.swf";
drawTable();
});
    </script>
  </head>

  <body id="dt_example">
  <div id="container">
  <table cellpadding="0" cellspacing="0" border="0" class="display" id="datatable">
  </table>
  </body>
  <head>
    <meta http-equiv='Pragma' content='no-cache'>
  </head>
</html>
