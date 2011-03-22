package System::Rtm::Host;

use strict;
use warnings;

use System;
class System::Rtm::Host {
    is => [ 'System::Rtm' ],
    table_name => 'host',
    id_by => [
        id => { },
    ],
    has => [
        availability => { },
        availability_method => { },
        avg_time => { },
        clusterid => { },
        cur_time => { },
        description => { },
        disabled => { },
        failed_polls => { },
        hostname => { },
        host_template_id => { },
        lic_server_id => { },
        max_oids => { },
        max_time => { },
        min_time => { },
        monitor => { },
        notes => { },
        ping_method => { },
        ping_port => { },
        ping_retries => { },
        ping_timeout => { },
        snmp_auth_protocol => { },
        snmp_community => { },
        snmp_context => { },
        snmp_password => { },
        snmp_port => { },
        snmp_priv_passphrase => { },
        snmp_priv_protocol => { },
        snmp_timeout => { },
        snmp_username => { },
        snmp_version => { },
        status => { },
        status_event_count => { },
        status_fail_date => { },
        status_last_error => { },
        status_rec_date => { },
        total_polls => { },
    ],
};

1;
