
package SDM::Disk::Filer::Command::Import;

use strict;
use warnings;

use SDM;

use Text::CSV;
use Data::Dumper;

$| = 1;

class SDM::Disk::Filer::Command::Import {
    is => 'SDM::Command::Base',
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
    my @filers;

    open my $fh, "<:encoding(utf8)", $self->csv or die "error opening file: " . $self->csv . ": $!";
    while ( my $row = $csv->getline( $fh ) ) {
        unless (@header) {
            next if ($row->[0] =~ /^#/);
            if ($row->[0] ne "name" or
                $row->[1] ne "type" or
                $row->[2] ne "hosts" or
                $row->[3] ne "comments") {
                $self->logger->error(__PACKAGE__ . " CSV file header does not match what is expected for Filers: " . $self->csv);
                return;
            }
            push @header, $row;
            next;
        }
        my $filer = {};
        # Build an object out of a row by hand because the column
        # headers are useless as is, with unpredictable/unusable text.
        $self->_store($filer, "name",         $row->[0]);
        $self->_store($filer, "type",         $row->[1]);
        $self->_store($filer, "hosts",        $row->[2]);
        $self->_store($filer, "comments",     $row->[3]);
        next unless (scalar keys %$filer);
        push @filers, $filer;
    }

    $csv->eof or $csv->error_diag();
    close $fh;

    if ($self->flush) {
        foreach my $filer (SDM::Disk::Filer->get()) {
            $filer->delete();
        }
    }

    foreach my $filerdata (@filers) {
        if (! defined $filerdata->{hosts} or ! defined $filerdata->{name}) {
            $self->logger->error(__PACKAGE__ . " malformed filer entry: " . Data::Dumper::Dumper $filerdata);
            next;
        }
        warn Data::Dumper::Dumper $filerdata if ($self->verbose);
        my @hosts = split(/\s+/,$filerdata->{hosts});
        @hosts = grep { /^\S+$/ } @hosts;
        foreach my $hostname (@hosts) {
            my $host = SDM::Disk::Host->get(hostname => $hostname);
            unless ($host) {
                $self->logger->error(__PACKAGE__ . " filer " . $filerdata->{name} . " refers to unknown host $hostname, perhaps import hosts first?");
                return;
            }
        }
        # Now create the filer
        my $filer = SDM::Disk::Filer->get_or_create(name => $filerdata->{name}, comments => $filerdata->{comments}, type => $filerdata->{type} );
        unless ($filer) {
            $self->logger->error(__PACKAGE__ . " error creating filer: " . Data::Dumper::Dumper $filerdata . ": $!");
        }
        foreach my $hostname (@hosts) {
            my $host = SDM::Disk::Host->get(hostname => $hostname);
            $host->assign( $filer->{name} );
        }
        # Make the first listed host the master
        my $master = shift @hosts;
        my $host = SDM::Disk::Host->get(hostname => $master);
        $host->master(1);
    }

    UR::Context->commit() if ($self->commit);
    $self->logger->info(__PACKAGE__ . " successfully imported " . scalar @filers . " filers");

    return 1;
}

1;
