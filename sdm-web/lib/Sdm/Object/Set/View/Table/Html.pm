
package Sdm::Object::Set::View::Table::Html;

use strict;
use warnings;

use Sdm;
use Data::Dumper;

class Sdm::Object::Set::View::Table::Html {
    is => 'UR::Object::View::Default::Html',
    has_constant => [
        default_aspects => {
            value => []
        }
    ]
};

=head2 _generate_content
Take the DATA content from the bottom of this file and text replace important bits.
We insert JSON data representing table rows.  We define sTitles for column headers.
We define a form to add a new row.
=cut
sub _generate_content {
    my $self = shift;
    my $content = do {
        local $/;
        <DATA>;
    };
    seek DATA, 0, 0;

    # Determine attributes of class for columns of the table
    my $class = $self->subject_class_name;
    $class =~ s/::Set//g;
    $content =~ s/<%= class =>/$class/g;

    # Create a unique table name for the DOM
    my $tablename = lc($class) . "table";
    $tablename =~ s/:://g;
    $content =~ s/<%= tablename =>/$tablename/g;

    # Build JSON view of aaData using Json.pm peer class
    my $subject = $self->subject;
    my $jsview;
    eval {
        $jsview = $subject->create_view('perspective'=>'table','toolkit'=>'json');
    };
    unless ($jsview) {
        eval {
            $jsview = $subject->create_view(subject_class_name => 'Sdm::Object::Set', 'perspective'=>'table','toolkit'=>'json');
        };
    }
    unless ($jsview) {
        die __PACKAGE__ . " failed to create view for JSON object for $class: $@";
    }

    # This is the table data.
    # Later we must figure out column headers and addForm data.
    # FIXME: Note multi-column IDs are not going to work.
    my $aaData = $jsview->_json->encode( $jsview->_jsobj->{aaData} );
    $content =~ s/<%= aaData =>/$aaData/;

    # Determine column headers for javascript
    my %args = (
            subject_class_name => $class,
            perspective => 'default',
            toolkit => 'json',
    );
    my @default_aspects;
    if ( $class->can('default_aspects') and $class->default_aspects ) {
        @default_aspects = @{ $class->default_aspects->{visible} };
    }
    unless (@default_aspects) {
        # Make the default_aspects all attributes of the object.
        warn "using all properties for table";
        @default_aspects = map { $_->property_name } $class->__meta__->properties;
    }

    # Here we set column attributes, like title.
    # We MUST include id, and it must be first, but may or may not be visible.
    # FIXME: replace 'id' with the id_by attribute of the object
    my $sTitles;
    if ( grep { /^id$/ } @default_aspects ) {
        $sTitles .= qq/{ "sTitle": "id" },\n/;
    } else {
        $sTitles .= qq/{ "sTitle": "id", "bVisible": false },\n/;
    }
    foreach my $attr (@default_aspects) {
        next if ($attr eq 'id');
        $sTitles .= qq/{ "sTitle": "$attr" },\n/;
    }
    $content =~ s/<%= sTitles =>/$sTitles/;

    # Here we specify which columns are not editable by setting 'null' in aoColumns
    # Note that 'id' is always present and first.
    my $editable = [];
    if ( $class->can('default_aspects') and $class->default_aspects ) {
        $editable = $class->default_aspects->{editable};
    }
    my $aoColumns;
    if ( grep { /^id$/ } @default_aspects ) {
        $aoColumns = qq/null,\n/; # id is never editable and always first, here it's visible too.
    } else {
        # Otherwise we ignore 'id'
    }
    foreach my $attr (@default_aspects) {
        if ( grep { /$attr/ } @$editable ) {
            $aoColumns .= qq/{},\n/;
        } else {
            $aoColumns .= qq/null,\n/;
        }
    }
    $content =~ s/<%= aoColumns =>/$aoColumns/;

    # Here we build the Add Record form
    # Be careful.  We must have 'id' and we've made sure we have it present first and hidden.
    # We might also display the 'id' or an id_by attribute.  These are sometimes even editable.
    # So make sure you have 'id' first hidden, then present all editable attributes in the form.
    my $idx = 0;
    # id is always first (0), and hidden in creation of a new record.
    my $addRecord = qq{  <input type="hidden" name="id" id="id" rel="$idx" /><br />\n };
    $idx++;
    foreach my $attr (@default_aspects) {
        if (grep { /$attr/ } @$editable) {
            $addRecord .= qq{  <label for="$attr">$attr</label><br />\n  <input type="text" name="$attr" id="$attr" class="required" rel="$idx" /><br />\n };
            $idx++;
        } else {
            $addRecord .= qq{  <input type="hidden" name="$attr" id="$attr" rel="$idx" /><br />\n };
            $idx++;
        }
    }
    $content =~ s/<%= addrecordform =>/$addRecord/;

    # Here's the HTML document we return
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
    <title><%= class =></title>
    <style type="text/css" title="currentStyle">
      @import "/css/status_page.css";
      @import "/css/status_table.css";
      @import "/css/jquery-ui.css";
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
    <script type="text/javascript" language="javascript" charset="utf-8">
        var oTable;
        function draw<%= tablename =>Table () {
            oTable = $('#<%= tablename =>').dataTable( {
                    "sDom": 'T<"clear">lfrtip',
                    "bProcessing": true,
                    "bServerSide": false,
                    // This callback adds the "id" tr attribute required for sUpdateURL to work
                    "fnRowCallback": function( nRow, aaData, iDisplayIndex ) {
                        var id = aaData[0];
                        $(nRow).attr("id",id);
                        return nRow;
                    },
                    // aaData is generated automatically by Json.pm
                    "aaData":
                      <%= aaData =>
                    ,
                    // hide the id which is a UUID
                    "aoColumns": [
                        <%= sTitles =>
                    ],
                    } ).makeEditable( {
                        sUpdateURL: "/service/update?class=<%= class =>",
                        sAddURL: "/service/add?class=<%= class =>",
                        //fnOnAdded: function(status) {
                        //  location.reload();
                        //},
                        sDeleteURL: "/service/delete?class=<%= class =>",
                        // Define columns here, which can be reordered in {Html,Json}.pm
                        // Prevent users from modifying created and last_modified
                        "aoColumns": [
                          <%= aoColumns =>
                        ],
                        "sAddNewRowFormId": "<%= tablename =>_formAddNewRow",
                        "sAddNewRowButtonId": "<%= tablename =>_btnAddNewRow",
                        "sAddNewRowOkButtonId": "<%= tablename =>_btnAddNewRowOk",
                        "sAddNewRowCancelButtonId": "<%= tablename =>_btnAddNewRowCancel",
                        "sDeleteRowButtonId": "<%= tablename =>_btnDeleteRow",
                        "sAddDeleteToolbarSelector": ".<%= tablename =>_toolbarSelector",
                    } );
        }
    </script>
    <script type="text/javascript" language="javascript" charset="utf-8">
$(document).ready(function() {
TableToolsInit.sSwfPath = "/js/pkg/TableTools/media/swf/ZeroClipboard.swf";
draw<%= tablename =>Table();
});
    </script>
  </head>

  <body id="dt_example">
  <div id="<%= tablename =>container">
  <table cellpadding="0" cellspacing="0" border="0" class="display" id="<%= tablename =>">
  </table>

  <div class="<%= tablename =>_toolbarSelector clear" />
  </div>
  <!-- Custom form for adding new records -->
  <form id="<%= tablename =>_formAddNewRow" action="#" title="Add new record">
    <%= addrecordform =>
  </form>
  </div>
  </body>
  <head>
    <meta http-equiv='Pragma' content='no-cache'>
  </head>
</html>
