
package SDM::Disk::Filer::Command::Import;

use strict;
use warnings;

use SDM;

use Text::CSV;
use Getopt::Std;
use Data::Dumper;

$| = 1;

class SDM::Disk::Filer::Command::Import {
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
    my @filers;

    open my $fh, "<:encoding(utf8)", $self->csv or die "error opening file: " . $self->csv . ": $!";
    while ( my $row = $csv->getline( $fh ) ) {
        unless (@header) {
            push @header, $row;
            next;
        }
        my $filer = {};
        # Build an object out of a row by hand because the column
        # headers are useless as is, with unpredictable/unusable text.
        $self->_store($filer, "name",         $row->[0]);
        $self->_store($filer, "hosts",        $row->[1]);
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

    foreach my $filer (@filers) {
        if (! defined $filer->{hosts} or ! defined $filer->{name}) {
            $self->logger->error(__PACKAGE__ . " malformed filer entry: " . Data::Dumper::Dumper $filer);
            next;
        }
        warn Data::Dumper::Dumper $filer if ($self->verbose);
        my @hosts = split(/\s+/,$filer->{hosts});
        @hosts = grep { /^\S+$/ } @hosts;
        foreach my $hostname (@hosts) {
            my $host = SDM::Disk::Host->get(hostname => $hostname);
            unless ($host) {
                $self->logger->error(__PACKAGE__ . " filer " . $filer->{name} . " refers to unknown host $hostname");
                return;
            }
        }
        my $result = SDM::Disk::Filer->get_or_create(name => $filer->{name});
        unless ($result) {
            $self->logger->error(__PACKAGE__ . " error creating filer: " . Data::Dumper::Dumper $filer . ": $!");
        }
        foreach my $hostname (@hosts) {
            my $host = SDM::Disk::Host->get(hostname => $hostname);
            $host->assign( $result->{name} );
        }

    }

    UR::Context->commit() if ($self->commit);
    return 1;
}

1;
