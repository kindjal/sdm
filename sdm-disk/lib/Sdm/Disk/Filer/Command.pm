package Sdm::Disk::Filer::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Filer::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk filers',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::Filer',
    target_name => 'filer',
    list => { show => 'name,type,status,hostname,arrayname,comments' }
);

1;
