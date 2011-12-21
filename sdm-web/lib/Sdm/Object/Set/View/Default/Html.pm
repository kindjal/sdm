
package Sdm::Object::Set::View::Default::Html;

use strict;
use warnings;
use feature 'switch';

use Sdm;
use Data::Dumper;

class Sdm::Object::Set::View::Default::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;

    # Determine attributes of class for columns of the table
    my $class = $self->subject_class_name;

    # Build JSON view of aaData using Json.pm peer class
    my $subject = $self->subject;
    my $jsview = $subject->create_view('perspective'=>'table','toolkit'=>'json');
    my $aaData = $jsview->_json->encode( $jsview->_jsobj->{aaData} );

    # Determine column headers for javascript
    my @members = $subject->members;
    my $member = $members[0];
    my %args = (
            subject_class_name => $class,
            perspective => 'default',
            toolkit => 'json',
    );
    $args{aspects} = $self->default_aspects if ($self->default_aspects);
    my $v = $member->create_view(%args);
    my @attributes = $v->aspects;
    @attributes = map { $_->name } @attributes;

    # Here's the javascript datatable for the class attributes.
    my $tablescript =<<EOF;
    <script type="text/javascript" language="javascript" charset="utf-8">
        var oTable;
        function drawTable () {
            oTable = \$('#datatable').dataTable( {
                    "sDom": 'T<"clear">lfrtip',
                    "bProcessing": true,
                    "bServerSide": false,
                    // This callback adds the "id" tr attribute required for sUpdateURL to work
                    "fnRowCallback": function( nRow, aaData, iDisplayIndex ) {
                        var id = aaData[0];
                        \$(nRow).attr("id",id);
                        return nRow;
                    },
                    // aaData is generated automatically by Json.pm
                    "aaData":
EOF
    # aaData is the JSON formatted table row data.
    $tablescript .= $aaData;
    $tablescript .= <<EOF;
                    ,
                    // hide the id which is a UUID
                    "aoColumns": [
                        { "sTitle":'id', "bVisible": false },
EOF
    # Here we set column attributes, like title.
    foreach my $attr (@attributes) {
        next if ($attr eq 'id');
        $tablescript .= qq/{ "sTitle": "$attr" },\n/;
    }
    # Here we define the makeEditable block for editable datatable.
    $tablescript .= <<EOF;
                    ],
                    } ).makeEditable( {
                        sUpdateURL: "/service/update?class=$class",
                        sAddURL: "/service/add?class=$class",
                        fnOnAdded: function(status) {
                          location.reload();
                        },
                        sDeleteURL: "/service/delete?class=$class",
                        // Define columns here, which can be reordered in {Html,Json}.pm
                        // Prevent users from modifying created and last_modified
                        "aoColumns": [
EOF
    # Here we specify which columns are not editable by setting 'null' in aoColumns
    foreach my $attr (@attributes) {
        given ($attr) {
            when ($attr eq 'id') { next; };
            when ($attr =~ /(created|last_modified)/i) {
                $tablescript .= qq/null,\n/;
                next;
            }
            default {
                $tablescript .= qq/{},\n/;
            }
        }
    }
    $tablescript .= <<EOF;
                        ]
            } );
        }
    </script>
EOF

    my $addrecordform = <<EOF;
  <!-- Custom form for adding new records -->
   <form id="formAddNewRow" action="#" title="Add new record">
EOF
    my $idx = 0;
    foreach my $attr (@attributes) {
        given ($attr) {
            # These are the none editable columns, hidden in the add form
            when ($attr =~ /^(id|created|last_modified)$/) {
                $addrecordform .= <<EOF;
                <input type="hidden" name="$attr" id="$attr" rel="$idx" /><br />
EOF
                $idx++;
                next;
            }
            default {
                $addrecordform .= <<EOF;
                <label for="$attr">$attr</label><br />
                <input type="text" name="$attr" id="$attr" class="required" rel="$idx" /><br />
EOF
               $idx++;
            }
        }
    }
    $addrecordform .= <<EOF;
  </form>
EOF

    # Here's the rest of the HTML document
    my $content;
    while (my $line = <DATA>) {
        $line =~ s/<%= classname %>/$class/;
        $line =~ s/<%= tablescript %>/$tablescript/;
        $line =~ s/<%= addrecordform %>/$addrecordform/;
        $content .= $line;
    }

    return $content;
}

1;
__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <!-- Disable browser caching -->
    <meta http-equiv='Pragma' content='no-cache'/>
    <!-- Microsoft browsers require this additional meta tag as well -->
    <meta http-equiv='Expires' content='-1'/>
    <title><%= classname %></title>
    <style type="text/css" title="currentStyle">
      @import "/css/status_page.css";
      @import "/css/status_table.css";
      @import "/js/pkg/TableTools/media/css/TableTools.css";
    </style>
    <link rel="shortcut icon" href="/images/gc_favicon.png" />
    <!-- <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jQuery/jquery.min.js"></script> -->
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/DataTables/media/js/jquery.dataTables.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/TableTools/media/ZeroClipboard/ZeroClipboard.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/TableTools/media/js/TableTools.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery-datatables-editable/jquery-ui.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery-datatables-editable/jquery.jeditable.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery-datatables-editable/jquery.validate.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/pkg/jquery-datatables-editable/jquery.dataTables.editable.js"></script>
    <script type="text/javascript" language="javascript" charset="utf-8" src="/js/app/common.js"></script>
    <%= tablescript %>
    <script type="text/javascript" language="javascript" charset="utf-8">
$(document).ready(function() {
TableToolsInit.sSwfPath = "/js/pkg/TableTools/media/swf/ZeroClipboard.swf";
drawTable();
});
    </script>
  </head>

  <body id="dt_example">
  <div id="container">
  <table cellpadding="0" cellspacing="0" border="0" class="display" id="datatable">
  </table>
  <!-- Placeholder where add and delete buttons will be generated -->
  <div class="add_delete_toolbar" />
  </div>
  <%= addrecordform %>
  </body>
  <head>
    <meta http-equiv='Pragma' content='no-cache'>
  </head>
</html>
