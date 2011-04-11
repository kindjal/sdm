
package System::Disk::Filer::Command::GpfsCrfs;

use System;
use IPC::Cmd qw/can_run/;
use File::Basename qw/basename/;

class System::Disk::Filer::Command::GpfsCrfs {
    is => 'System::Command::Base',
    doc => 'Create a GPFS filesystem',
    has => [
        volume => { is => 'System::Disk::Volume', doc => 'Volume identified by mount path' },
        array  => { is => 'System::Disk::Array', doc => 'Array identified by array name' },
        number => { is => 'Number', doc => 'The number of GPFS NSDs to apply to this filesystem' },
    ],
};

sub help_brief {
    return 'Observe free GPFS NDSs and apply them to a filesystem';
}

sub help_synopsis {
    return <<EOS
Observe free GPFS NDSs and apply them to a filesystem
EOS
}

sub help_detail {
    return <<EOS
Observe free GPFS NDSs and apply them to a filesystem
EOS
}

sub execute {
    my $mmls = can_run("mmlsnsd");
    unless ($mmls) {
        $self->error_message("cannot find mmlsnsd in PATH");
        return;
    }
    my $mmcr = can_run("mmcrfs");
    unless ($mmcr) {
        $self->error_message("cannot find mmcrfs in PATH");
        return;
    }

    my @args;
    open(CMD,"$mmls -F |") or die "error running mmlsnsd: $!";
    while (<>) {
        # Strip output header
        next until ($. > 3);
        next unless (/\s+$self->array->name\s+/);
        last if ($#args == $self->count - 1);
        my $nsd = @{ [ split(/\s+/) ] }[2];
        push @args, $nsd;

    }
    close(CMD);

    my $arg = join(";",@args);
    my $vol = basename $volume->physical_path;
    my $cmd = "$mmcr $volume->physical_path $vol $arg -A yes";
    # FIXME:
    my $response = $self->_ask_user_question("Ok to run [Y|n]: $cmd",'Y','n');
    return unless ($response =~ /y/i);
    system($cmd);
    if ($? == -1) {
         $self->error_message("failed to execute: $!");
    } elsif ($? & 127) {
         $self->error_message("child died with signal %d, %s coredump", ($? & 127),  ($? & 128) ? 'with' : 'without');
    } else {
         $self->warning_message("child exited with value %d\n", $? >> 8);
    }
    return $? >> 8;
}

1;
