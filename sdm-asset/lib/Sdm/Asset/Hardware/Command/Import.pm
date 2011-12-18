
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

    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
        or die "Cannot use CSV: " . Text::CSV->error_diag();

    my @header;
    my @assets;

    open my $fh, "<:encoding(utf8)", $self->csv or die "error opening file: " . $self->csv . ": $!";
    while ( my $row = $csv->getline( $fh ) ) {
        unless (@header) {
            # Here represent reading columns from CSV, which must match table columns
            #  manufacturer  VARCHAR(255),
            #  model         VARCHAR(255),
            #  serial        VARCHAR(255),
            #  description   VARCHAR(255),
            #  comments      VARCHAR(255),
            #  location      VARCHAR(255),
            if ($row->[0] ne "manufacturer" or
                $row->[1] ne "model" or
                $row->[2] ne "serial" or
                $row->[3] ne "description" or
                $row->[4] ne "comments" or
                $row->[5] ne "location"
               ) {
                $self->logger->error(__PACKAGE__ . " CSV file header does not match what is expected for Assets: " . $self->csv);
                return;
            }
            push @header, $row;
            next;
        }
        my $asset = {};
        # Build an object out of a row by hand because the column
        # headers are useless as is, with unpredictable/unusable text.
        $self->_store($asset, "manufacturer", $row->[0]);
        $self->_store($asset, "model",        $row->[1]);
        $self->_store($asset, "serial",       $row->[2]);
        $self->_store($asset, "description",  $row->[3]);
        $self->_store($asset, "comments",     $row->[4]);
        $self->_store($asset, "location",     $row->[5]);
        next unless (scalar keys %$asset);
        push @assets, $asset;
    }

    $csv->eof or $csv->error_diag();
    close $fh;

    if ($self->flush) {
        foreach my $asset (Sdm::Asset::Hardware->get()) {
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
