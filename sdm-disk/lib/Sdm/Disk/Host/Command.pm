package Sdm::Disk::Host::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Host::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk hosts',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::Host',
    target_name => 'host',
    list => { show => 'hostname,filername,arrayname,os,location,status,comments' }
);

1;
