
package SDM::Tool::Command::ArrayIops;

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse = 1;

class SDM::Tool::Command::ArrayIops {
    is => 'SDM::Command::Base',
    doc => 'calculate IOPS on named array',
    has => [
        hostname => {
            is => 'Text',
            doc => 'hostname of array to query, possibly a comma separated list'
        },
        fcport => {
            is => 'Text',
            doc => 'fiber channel port, eg. fc4/47, possibly a comma separated list'
        },
        size => {
            is => 'Number',
            doc => 'block offset size',
            default_value => 128
        }
    ],
    has_optional => [
        raid => {
            is => 'Number',
            doc => 'RAID level',
            valid_values => [undef,5,6],
        },
    ],
    has_transient => [
        total_reads => {
            is => 'Number',
            default_value => 0
        },
        total_writes => {
            is => 'Number',
            default_value => 0
        }
    ]
};

sub calculate {
    my $self = shift;
    my $table = shift;
    my $fcport = shift;
    my $found = 0;
    my $read;
    my $write;
    unless ($fcport) {
        $self->logger->error(__PACKAGE__ . " please specify desired fiber channel port with --fcport");
        exit 1;
    }
    $self->logger->debug(__PACKAGE__ . " look up $fcport");
    foreach my $index ( keys %$table ) {
        next unless ($table->{$index}->{ifDescr} eq $fcport);
        $found = 1;
        $read = $table->{$index}->{ifHCInUcastPkts};
        $write = $table->{$index}->{ifHCOutUcastPkts};
        last;
    }
    unless ($found) {
        $self->logger->debug(__PACKAGE__ . " fiber channel port not found: $fcport");
        return (0,0);
    }
    $self->logger->debug(__PACKAGE__ . " raw read: $read, raw write: $write");
    if ($self->size) {
        $read /= $self->size;
        $write /= $self->size;
    }
    if ($self->raid) {
        $write *= 4 if ($self->raid == 5);
        $write *= 6 if ($self->raid == 6);
    }
    return ($write,$read);
}

sub query_host {
    my $self = shift;
    my $hostname = shift;
    $self->logger->debug(__PACKAGE__ . " SNMP query $hostname");

    my $snmp = SDM::Utility::SNMP->create( hostname => $hostname, loglevel => $self->loglevel );

    # Build a hash of 3 snmp tables:
    my $a = $snmp->read_snmp_into_table('ifDescr');
    my $b = $snmp->read_snmp_into_table('ifHCInUcastPkts');
    my $c = $snmp->read_snmp_into_table('ifHCOutUcastPkts');
    my $snmp_table;
    while (my ($k,$v) = each %$a) {
        $snmp_table->{$k} = $v;
    }
    while (my ($k,$v) = each %$b) {
        $snmp_table->{$k} = { %{$snmp_table->{$k}}, %$v };
    }
    while (my ($k,$v) = each %$c) {
        $snmp_table->{$k} = { %{$snmp_table->{$k}}, %$v };
    }

    foreach my $fcport ( split(",",$self->fcport) ) {
        my ($write,$read) = $self->calculate($snmp_table,$fcport);
        $self->total_writes( $self->total_writes + $write );
        $self->total_reads( $self->total_reads + $read );
    }
}

sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " acquire_data");

    foreach my $hostname ( split(",",$self->hostname) ) {
        $self->query_host($hostname);
    }

    printf "GPFS OK|writes=%s reads=%s total=%s\n", $self->total_writes, $self->total_reads, $self->total_writes + $self->total_reads;
    return 1;
}

1;
