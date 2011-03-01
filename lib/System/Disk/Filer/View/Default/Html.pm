use strict;
use warnings;
use System;

package System::Disk::Filer::View::Default::Html;

class System::Disk::Filer::View::Default::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    return "<html>hi</html>";
}

1;
