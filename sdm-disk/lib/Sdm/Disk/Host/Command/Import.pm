
package Sdm::Disk::Host::Command::Import;

use strict;
use warnings;

use Sdm;

use Text::CSV;
use Getopt::Std;
use Data::Dumper;

$| = 1;

class Sdm::Disk::Host::Command::Import {
    is => 'Sdm::Command::Base',
    doc => 'Import filer data from CSV file',
    has => [
        csv     => { is => 'Text', doc => 'CSV file name' }
    ],
    has_optional => [
        commit  => { is => 'Boolean', doc => 'Commit after parsing CSV', default => 1 },
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
            if (
                "hostname" ne $row->[0] or
                "arrays" ne $row->[1] or
                "status" ne $row->[2] or
                "manufacturer" ne $row->[3] or
                "model" ne $row->[4] or
                "os" ne $row->[5] or
                "location" ne $row->[6] or
                "comments" ne $row->[7] or
                "master" ne $row->[8] or
                "created" ne $row->[9] or
                "last_modified" ne $row->[10]) {
                $self->logger->error(__PACKAGE__ . " CSV file header doesn't match what is expected for Hosts: " . $self->csv);
                return;
            }
            push @header, $row;
            next;
        }
        my $host = {};
        # Build an object out of a row by hand because the column
        # headers are useless as is, with unpredictable/unusable text.
        $self->_store($host, "hostname",       $row->[0]);
        $self->_store($host, "arrays",         $row->[1]);
        $self->_store($host, "status",         $row->[2]);
        $self->_store($host, "manufacturer",   $row->[3]);
        $self->_store($host, "model",          $row->[4]);
        $self->_store($host, "os",             $row->[5]);
        $self->_store($host, "location",       $row->[6]);
        $self->_store($host, "comments",       $row->[7]);
        $self->_store($host, "master",         $row->[8]);
        $self->_store($host, "created",        $row->[9]);
        $self->_store($host, "last_modified",  $row->[10]);
        push @hosts, $host;
    }

    $csv->eof or $csv->error_diag();
    close $fh;

    if ($self->flush) {
        foreach my $host (Sdm::Disk::Host->get()) {
            $host->delete();
        }
    }

    foreach my $hostdata (@hosts) {
        if ($self->verbose) {
            warn Data::Dumper::Dumper $hostdata;
        }
        my $host = Sdm::Disk::Host->get($hostdata->{hostname});
        my $arraylist = delete $hostdata->{arrays};
        if ($host) {
            $host->update(%$hostdata);
        } else {
            $host = Sdm::Disk::Host->create(%$hostdata);
        }
        unless ($host) {
            $self->logger->error(__PACKAGE__ . " failed to get or create host: " . Data::Dumper::Dumper $hostdata . ": $!");
            return;
        }
        if ($arraylist) {
            my $array;
            my $arrayname;
            my @arraynames = split(/\s+/,$arraylist);
            foreach $arrayname (@arraynames) {
                $array = Sdm::Disk::Array->get(name => $arrayname);
                unless ($array) {
                    $self->logger->error(__PACKAGE__ . " failed to associate array $arrayname to host " . $host->hostname . ".  Perhaps import array data first.");
                    return;
                }
                $array->assign( $host->hostname );
            }
        }
    }

    UR::Context->commit() if ($self->commit);
    $self->logger->info(__PACKAGE__ . " successfully imported " . scalar @hosts . " hosts");
    return 1;
}

1;
