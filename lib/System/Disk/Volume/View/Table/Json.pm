package System::Disk::Volume::View::Table::Json;

use strict;
use warnings;

use System;
use JSON;

class System::Disk::Volume::View::Table::Json {
    is => 'UR::Object::View::Table::Json',
};

sub _generate_content {
    my $self;
    my $v = '{"iTotalRecords":1379,"iTotalDisplayRecords":1379,"aaData":[["/gscmnt/xp105","/vol/xp105","3,006,349,312 (3 TB)","5,172 (5 MB)",0,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"],["/gscmnt/xp1101","/vol/xp1101","3,006,349,312 (3 TB)","5,156 (5 MB)",0,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"],["/gscmnt/xp126","/vol/xp126","3,006,349,312 (3 TB)","570,435,244 (570 GB)",18.97,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"],["/gscmnt/xp191","/vol/xp191","3,006,349,312 (3 TB)","77,615,152 (78 GB)",2.58,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"],["/gscmnt/xp122","/vol/xp122","3,006,349,312 (3 TB)","595,063,600 (595 GB)",19.79,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"],["/gscmnt/xp119","/vol/xp119","3,006,349,312 (3 TB)","329,400,172 (329 GB)",10.96,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"],["/gscmnt/xp181","/vol/xp181","3,006,349,312 (3 TB)","1,749,851,324 (2 TB)",58.21,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"],["/gscmnt/xp1102","/vol/xp1102","3,006,349,312 (3 TB)","974,727,412 (975 GB)",32.42,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"],["/gscmnt/xp127","/vol/xp127","3,006,349,312 (3 TB)","5,156 (5 MB)",0,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"],["/gscmnt/xp192","/vol/xp192","3,006,349,312 (3 TB)","445,440,340 (445 GB)",14.82,"PRODUCTION_SOLEXA","2011-03-07 07:01:06"]],"sEcho":1}';
    return $v;
}

1;
