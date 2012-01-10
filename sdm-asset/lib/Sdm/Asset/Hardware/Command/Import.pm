
package Sdm::Asset::Hardware::Command::Import;

use strict;
use warnings;

use Sdm;

use Text::CSV;
use Data::Dumper;

class Sdm::Asset::Hardware::Command::Import {
    is => 'Sdm::Command::Base',
    doc => 'Import hardware data from CSV file',
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
    return 'Import asset data from a CSV file';
}

sub help_synopsis {
    return <<EOS;
Import asset data from a CSV file
EOS
}

sub help_detail {
    return <<EOS;
Import asset data from a CSV file
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
    my $class = 'Sdm::Asset::Hardware';

    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
        or die "Cannot use CSV: " . Text::CSV->error_diag();

    my @header;
    my @assets;

    open my $fh, "<:encoding(utf8)", $self->csv or die "error opening file: " . $self->csv . ": $!";
    while ( my $row = $csv->getline( $fh ) ) {
        # Assume header is first row.
        unless (@header) {
            @header = @$row;
            next;
        }
        my $asset = {};
        foreach my $i (0..$#header) {
            next unless ($class->can($header[$i]));
            $self->_store($asset, $header[$i], $row->[$i]);
        }
        next unless (scalar keys %$asset);
        push @assets, $asset;
    }

    $csv->eof or $csv->error_diag();
    close $fh;

    if ($self->flush) {
        foreach my $asset ($class->get()) {
            $asset->delete();
        }
    }

    # Parse each line and do any special processing to create the objects
    foreach my $asset (@assets) {
        warn Data::Dumper::Dumper $asset if ($self->verbose);
        my $obj = Sdm::Asset::Hardware->get_or_create( %$asset );
        unless ($obj) {
            $self->logger->error(__PACKAGE__ . " error creating asset: " . Data::Dumper::Dumper $asset . ": $!");
        }
    }

    UR::Context->commit() if ($self->commit);
    $self->logger->info(__PACKAGE__ . " successfully imported " . scalar @assets. " assets");

    return 1;
}

1;
