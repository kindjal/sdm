

use strict;
use warnings;

package Record;

sub new {
    my $class = shift;
    my $self = {
        id => shift
    };
    bless $self,$class;
    return $self;
}

sub push {
    my $self = shift;
    my @fields = @_;
    my $column = 0;
    foreach my $field (@fields) {
        push @{ $self->{$column} }, int($field);
        $column++;
    }
}

sub avg {
    my $self = shift;
    my $column = shift;
    my $sum = 0;
    foreach (@{ $self->{$column} }) { $sum+=$_ };
    my $count = scalar @{ $self->{$column} };
    return $sum / $count;
};

package Sdm::Tool::Command::ParseCollectl;

use Sdm;
use Date::Format qw/time2str/;
use Net::SSH;

class Sdm::Tool::Command::ParseCollectl {
    is => 'Sdm::Command::Base',
    doc => 'parse a collectl log and average one of the columns over a time range',
    has => [
        hostname => {
            is => 'Text',
            doc => 'target hostname'
        },
        filename => {
            is => 'Text',
            default_value => "/var/log/collectl/" . Sys::Hostname::hostname . "-" . Date::Format::time2str((q|%Y%m%d|), time()) . "-000000.raw.gz",
            doc => 'collectl log file name'
        },
        range => {
            is => 'Text',
            default_value => Date::Format::time2str((q|%H:%M|), time() - 3600) . "-" . Date::Format::time2str((q|%H:%M|), time()),
            doc => 'time range to look in the collectl log for'
        },
        collectl => {
            is => 'Text',
            default_value => "collectl",
            doc => 'path to collectl executable'
        },
        column => {
            is => 'Number',
            default_value => 12,
            doc => 'column of collectl log to calculate'
        },
        limit => {
            is => 'Number',
            default_value => 10,
            doc => 'display the top N results'
        }
    ],
    has_optional => [
        args => {
            is => 'Text',
            doc => 'collectl replay args'
        },
    ],
    has_transient => [
        table => {
            is => 'Hash',
            default_value => {},
            doc => 'hash table of stored results'
        }
    ]
};

sub _exit {
    my $self = shift;
    my $msg = shift;
    $self->logger->error($msg);
    exit 1;
}

sub get_filehandle {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " get_filehandle");

    my $cmd = $self->collectl . " " . $self->args;
    $self->logger->info(__PACKAGE__ . " " . $cmd);

    if ($self->hostname eq 'localhost') {
        open(READER, "$cmd 2>/dev/null |") or die "open error: $!";
        return *READER;
    }

    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "$cmd") or $self->_exit("error: $cmd: $!");
    close(WRITER);
    close(ERROR);
    while(<READER>) {
        chomp;
        next if (/^(#|$)/);
        if (/^Error/) {
            die "collectl error: " . $_;
        }
        $self->parseline($_);
    }
    return *READER;
}

sub parseline {
    my $self = shift;
    my $line = shift;
    my @fields = split((/\s+/), $line);
    # Here column 0 is id of a record
    my $name = shift @fields;
    if ($self->{table}->{$name}) {
        $self->{table}->{$name}->push(@fields);
    } else {
        my $obj = Record->new($name);
        my $column = 0;
        foreach my $attr (@{ $self->{attrs} }) {
            $obj->{$column} = [];
            $column++;
        }
        $obj->push(@fields);
        $self->{table}->{$name} = $obj;
    }
}

sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    unless ($self->args) {
        $self->args( "-p " . $self->filename . " -sD --from " . $self->range . " --hr 0" );
    }

    # Could be local file or Net::SSH connection
    my $reader = $self->get_filehandle;

    my $header;
    while(<$reader>) {
        chomp;
        next if (/^(#|$)/);
        # Collectl sends errors to stdout, not stderr.
        if (/^Error/) {
            die "error: " . $self->collectl . ": " . $_;
        }
        $self->parseline($_);
    }
    close($reader);
    if ($? == -1) {
        $self->logger->error("failed to execute: $!");
    } elsif ($? & 127) {
        my $msg = sprintf "child died with signal %d, %s coredump\n",
           ($? & 127),  ($? & 128) ? 'with' : 'without';
        $self->logger->error("failed to execute: $msg");
    }

    my $count = 0;
    my $col = $self->{column} - 1;
    foreach my $name (reverse sort { $self->{table}->{$a}->avg($col) cmp $self->{table}->{$b}->avg($col) } @{ [ keys %{ $self->{table} } ] } ) {
        print "$name " . $self->{table}->{$name}->avg($col) . "\n";
        $count++;
        last if ($count >= $self->limit);
    }

    return 1;
}

1;
