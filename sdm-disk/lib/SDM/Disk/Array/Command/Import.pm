
package SDM::Disk::Array::Command::Import;

use strict;
use warnings;

use SDM;

use Text::CSV;
use Getopt::Std;
use Data::Dumper;

$| = 1;

class SDM::Disk::Array::Command::Import {
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
    my $newv = $value;
    $hash->{$key} = $newv;
}

sub execute {
    my $self = shift;

    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
        or die "Cannot use CSV: " . Text::CSV->error_diag();

    my @header;
    my @arrays;
    my @dsets;

    open my $fh, "<:encoding(utf8)", $self->csv or die "error opening file: " . $self->csv . ": $!";
    while ( my $row = $csv->getline( $fh ) ) {
        unless (@header) {
            if ("name" ne $row->[0]      or
                "manufacturer" ne $row->[1] or
                "model" ne $row->[2]     or
                "serial" ne $row->[3]    or
                "disk_type" ne $row->[4] or
                "disk_num" ne $row->[5]
                ) {
                $self->logger->error(__PACKAGE__ . " CSV file  ne does not match what is expected for Filers: " . $self->csv);
                return;
            }
            push @header, $row;
            next;
        }
        next unless (defined $row->[4] and defined $row->[5]);
        next unless ($row->[4] =~ m/^\S+$/ and $row->[5] =~ m/^\S+$/);
        my $array = {};
        my $dset = {};
        # Build an object out of a row by hand because the column
        # headers are useless as is, with unpredictable/unusable text.
        $self->_store($array, "name",         $row->[0]);
        $self->_store($array, "manufacturer", $row->[1]);
        $self->_store($array, "model",        $row->[2]);
        $self->_store($array, "serial",       $row->[3]);
        $self->_store($dset , "arrayname",    $row->[0]);
        $self->_store($dset, "disk_type",     $row->[4]);
        $self->_store($dset, "disk_num",      int( $row->[5] ));
        $self->_store($dset, "disk_size",     int( $row->[7] * 1024 * 1024 ));
        $self->_store($array, "comments",     $row->[12]);
        next unless (scalar keys %$array and scalar keys %$dset);
        push @arrays, $array;
        push @dsets, $dset;
    }

    $csv->eof or $csv->error_diag();
    close $fh;

    if ($self->flush) {
        foreach my $dset (SDM::Disk::ArrayDiskSet->get()) {
            $dset->delete();
        }
        foreach my $array (SDM::Disk::Array->get()) {
            $array->delete();
        }
    }

    foreach my $arraydata (@arrays) {
        print Data::Dumper::Dumper $arraydata if ($self->verbose);
        my $array = SDM::Disk::Array->get($arraydata->{name});
        if ($array) {
            $array->update(%$arraydata);
        } else {
            $array = SDM::Disk::Array->create(%$arraydata);
        }
        unless ($array) {
            $self->logger->error(__PACKAGE__ . " failed to get or create array: " . Data::Dumper::Dumper $arraydata . ": $!");
        }
    }
    foreach my $dset (@dsets) {
        print Data::Dumper::Dumper $dset if ($self->verbose);
        my @res = SDM::Disk::ArrayDiskSet->get_or_create(%$dset);
    }

    UR::Context->commit() if ($self->commit);

    $self->logger->info(__PACKAGE__ . " successfully imported " . scalar @arrays . " arrays");
    return 1;
}

1;
