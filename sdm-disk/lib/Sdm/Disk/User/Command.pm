package Sdm::Disk::User::Command;
# FIXME: Does this class need to exist?
# What are we going to do with Users?

use strict;
use warnings;

use Sdm;

class Sdm::Disk::User::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk users',
    is_abstract => 1
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::User',
    target_name => 'user',
    list => { show => 'email' }
);

1;
