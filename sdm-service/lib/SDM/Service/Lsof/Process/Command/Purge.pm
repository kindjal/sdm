
package SDM::Service::Lsof::Process::Command::Purge;

use strict;
use warnings;

use SDM;
use Date::Manip;
use Data::Dumper;

class SDM::Service::Lsof::Process::Command::Purge {
    is => 'SDM::Command::Base',
    has => [
        age => {
            is => 'Number',
            default_value => 86400,
            doc => 'seconds beyond which we shall purge',
        },

    ],
    doc => 'purge lsof process entries that have not been updated since threshold',
};

sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");
    my $count = 0;
    my @entries = SDM::Service::Lsof::Process->get();
    foreach my $item (@entries) {
        my $age = $item->age;
        $self->logger->debug(__PACKAGE__ . " age in seconds: $age");
        if ($age > $self->age) {
            $self->logger->debug(__PACKAGE__ . " remove stale entry: " . $item->hostname . " " . $item->pid);
            $item->delete;
            $count++;
        }
    }
    $self->logger->info(__PACKAGE__ . " removed $count items");
    return $count;
}

1;
