
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
    # FIXME: Rather "get" items where last_modified is > $self->age, but I
    # don't know how to do that.
    my @entries = SDM::Service::Lsof::Process->get();
    foreach my $item (@entries) {
        my $lm = $item->last_modified;
        next unless ($lm);
        $lm =~ s/[- ]/:/g;
        my $date = new Date::Manip::Date;
        my $err = $date->parse($lm);
        my $sec = $date->printf('%s');
        $self->logger->debug(__PACKAGE__ . " $sec");
        if ($self->age > (time - $sec)) {
            $self->logger->debug(__PACKAGE__ . " remove stale entry: " . $item->hostname . " " . $item->pid);
            $item->delete;
            $count++;
        }
    }
    $self->logger->info(__PACKAGE__ . " removed $count items");
    return $count;
}

1;
