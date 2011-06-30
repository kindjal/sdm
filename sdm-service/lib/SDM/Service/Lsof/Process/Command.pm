package SDM::Service::Lsof::Process::Command;

use SDM;
use strict;
use warnings;

class SDM::Service::Lsof::Process::Command {
    is          => 'Command::Tree',
    doc         => 'Work with lsof processes',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Service::Lsof::Process',
    target_name => 'process',
    list   => { show => 'hostname,pid,command,user,uid,time,timedelta,filename' },
    add    => { do_not_init => 1 },
    update => { do_not_init => 1 },
    delete => { do_not_init => 1 },
);

1;
