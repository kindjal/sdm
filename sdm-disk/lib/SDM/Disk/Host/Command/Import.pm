
package SDM::Disk::Host::Command::Import;

use strict;
use warnings;

use SDM;

use Text::CSV;
use Getopt::Std;
use Data::Dumper;

$| = 1;

class SDM::Disk::Host::Command::Import {
    is => 'SDM::Command::Base',
    doc => 'Import filer data from CSV file',
    has => [
        csv     => { is => 'Text', doc => 'CSV file name' }
    ],
    has_optional => [
        commit  => { is => 'Boolean', doc => 'Commit after parsing CSV' },
        flush   => { is => 'Boolean', doc => 'Flush DB before parsing CSV' },
        verbose => { is => 'Boolean', doc => 'Be verbose' },
    ],
};

sub help_brief {
    return 'Import filer data from a CSV file';
}

sub help_synopsis {
    return <<EOS;
Import filer data from a CSV file
EOS
}

sub help_detail {
    return <<EOS;
Import filer data from a CSV file
EOS
}

sub _store ($$$) {
    my $self = shift;
    my ($hash,$key,$value) = @_;
    return unless (defined $value and defined $key and length($value) > 0 and length($key) > 0);
    $hash->{$key} = $value;
}

sub execute {
    my $self = shift;

    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
        or die "Cannot use CSV: " . Text::CSV->error_diag();

    my @header;
    my @hosts;

    open my $fh, "<:encoding(utf8)", $self->csv or die "error opening file: " . $self->csv . ": $!";
    while ( my $row = $csv->getline( $fh ) ) {
        unless (@header) {
            push @header, $row;
            next;
        }
        my $host = {};
        # Build an object out of a row by hand because the column
        # headers are useless as is, with unpredictable/unusable text.
        $self->_store($host, "hostname",       $row->[0]);
        $self->_store($host, "status",         $row->[1]);
        $self->_store($host, "manufacturer",   $row->[2]);
        $self->_store($host, "model",          $row->[3]);
        $self->_store($host, "os",             $row->[4]);
        $self->_store($host, "location",       $row->[5]);
        $self->_store($host, "master",         $row->[6]);
        $self->_store($host, "created",        $row->[7]);
        $self->_store($host, "last_modified",  $row->[8]);
        push @hosts, $host;
    }

    $csv->eof or $csv->error_diag();
    close $fh;

    if ($self->flush) {
        foreach my $host (SDM::Disk::Host->get()) {
            $host->delete();
        }
    }

    foreach my $host (@hosts) {
        if ($self->verbose) {
            warn Data::Dumper::Dumper $host;
        }
        my $res = SDM::Disk::Host->get_or_create(%$host);
        unless ($res) {
            $self->logger->error("failed to get or create host: " . Data::Dumper::Dumper $host . ": $!");
        }
    }

    UR::Context->commit() if ($self->commit);
    return 1;
}

1;
