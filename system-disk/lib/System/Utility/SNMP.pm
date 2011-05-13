
package System::Utility::SNMP;

use strict;
use warnings;

use System;

use SNMP;
use Net::SNMP qw/:snmp/;
use IPC::Cmd qw/can_run/;
use Data::Dumper;

class System::Utility::SNMP {
    is => 'System::Command::Base',
    has => [
        community   => { is => 'Text', default => "gscpublic" },
        version     => { is => 'Text', default => "2c" },
        command     => { is => 'Text', default => "snmpget" },
        exec        => {
                        calculate_from => 'command',
                        calculate => q/
                            return unless ($command eq 'snmpget' or $command eq 'snmpwalk');
                            my $path = IPC::Cmd::can_run($command);
                            return unless ($path);
                            return join(" ",$path,"-v",$self->version,"-c",$self->community);
                        /,
                       },
    ],
    has_optional => [
        hostname     => { is => 'Text' },
        hosttype     => { is => 'Text' },
        prefixes     => { is => 'List',   default => [ '/vol','/home','/gpfs' ] },
    ],
};

=head2 _get_host_type
We expect different MIB support by host type, linux vs. netapp vs. linux+gpfs for example.
Return the detected host type.
  eg: SNMPv2-MIB::sysDescr.0 = STRING: "NetApp Release 7.3.2: Thu Oct 15 04:12:15 PDT 2009"
  value => "NetApp Release 7.3.2: Thu Oct 15 04:12:15 PDT 2009"
  host type becomes "netapp"
=cut
sub _get_host_type {
    my $self = shift;
    # This optional arg allows us to call _get_host_type in create() below.
    my $arg = shift;
    $self->hostname($arg) if ($arg);

    $self->logger->debug(__PACKAGE__ . " _get_host_type(" . $self->hostname .")");
    $self->command('snmpget');

    my $results = $self->run( 'sysDescr.0' );
    my $typehash = pop @$results;

    my $typestr = '';
    if ($typehash) {
        $typestr = $typehash->{value};
        $typestr = [ split(/\s+/,$typestr) ]->[0];
        $typestr =~ s/"//g;
    }
    $self->hosttype( lc($typestr) );
    return $self->hosttype;
}

=head2 _parse_result
Parse a list of SNMP get/walk results into hashes.
The results of the SNMP query are lines that look like:
  NETAPP-MIB::df64SisSavedKBytes.21 = Counter64: 0
I split this around "=" because of variations in left and right side that make a single regex a little hard to read.
LHS: /^(\S+)::(\S+)\.(\d+|"\S+")$/ =>  $mib $oid $idx where sometimes idx is numeric and other times a string.
RHS: /^(|(\S+):\s+)(.*)$/ => $type $value where sometimes type is empty.
=cut
sub _parse_snmp_line {
    my $self = shift;
    my $line = shift;
    # Debug logging here to very verbose.
    #$self->logger->debug(__PACKAGE__ . " _parse_snmp_line: $line");
    my $hash;
    return if ($line =~ /No Such Object/);
    my ($oid,$value) = split(/\s+=\s+/,$line);
    $oid =~ /^(\S+)::(\S+)\.(\d+|"\S+")$/;
    $hash = {
        mib   => $1,
        oid   => $2,
        idx   => $3,
    };
    unless ($value ) {
        $self->logger->error(__PACKAGE__ . " snmp result parse error: $line");
        return;
    }
    $value =~ /^(|(\S+):\s+)(.*)$/;
    my ($first,$second) = split(/: /,$value,2);
    if (defined $second) {
        $hash->{type} = $first;
        $hash->{value} = $second;
    } else {
        $hash->{type} = undef;
        $hash->{value} = $first;
    }
    foreach my $k (keys %$hash) {
        unless (exists $hash->{$k}) {
            $self->logger->error(__PACKAGE__ . " snmp result parse error: $line");
        }
    }

    return $hash;
}

=head2 read_snmp_into_table
Query SNMP OID and return a hash table of the results.
=cut
sub read_snmp_into_table {
    my $self = shift;
    my $oid = shift;
    $self->logger->debug(__PACKAGE__ . " read_snmp_into_table($oid)");
    my $table = {};
    $self->command('snmpwalk');
    my $results = $self->run($oid);
    foreach my $hash (@$results) {
        my $idx = $hash->{idx};
        $idx =~ s/"//g;
        my $oid  = $hash->{oid};
        $table->{$idx} = {} unless (exists $table->{$idx});
        my $value = $hash->{value};
        $value =~ s/"//g;
        $table->{$idx}->{$oid} = $value;
    }
    $self->logger->debug(__PACKAGE__ . " $oid " . scalar(keys %$table) . " items");
    return $table;
}

=head2 run
Running this SNMP class means running either snmpwalk or snmpget for an OID and returning
a list of hashes representing the returned list of SNMP lines.
=cut
sub run {
    my $self = shift;
    my $oid = shift;
    return unless ($oid);
    my @results = ();
    my $cmd = join(" ",$self->exec,$self->hostname,$oid);
    $self->logger->debug(__PACKAGE__ . " run $cmd");
    open FH, "$cmd |" or die "failed to run $self->exec: $!";
    while (<FH>) {
        chomp;
        my $hash = $self->_parse_snmp_line($_);
        next unless ($hash);
        push @results, $hash;
    }
    close(FH);
    return \@results;
}

=head2 create
We need to detect hosttype as soon as possible, so we do so at creation time.
Note then that we run snmpget/walk as we create this object.
=cut
sub create {
    my $class = shift;
    my (%params) = @_;
    unless ($params{hostname}) {
        $class->error_message("specify target hostname for create()");
        return;
    }
    my $obj = $class->SUPER::create( %params );
    my $hosttype = $obj->_get_host_type($params{hostname});
    unless ($hosttype) {
        $class->error_message("failed to determine host type for $params{hostname}");
        return;
    }
    $obj->hosttype($hosttype);
    $obj->command($params{command});
    return $obj;
}

1;
