
package SDM::Disk::Filer::Command::GpfsCrfs;

use SDM;
use File::Basename qw/basename/;
use Net::SSH qw/sshopen2/;

class SDM::Disk::Filer::Command::GpfsCrfs {
    is => 'SDM::Command::Base',
    doc => 'Create a GPFS filesystem',
    has => [
        filer  => { is => 'SDM::Disk::Filer', doc => 'Filer identified by filer name' },
        volume => { is => 'Text', doc => 'Volume identified by mount path' },
        number => { is => 'Number', doc => 'The number of GPFS NSDs to apply to this filesystem', default => 1 },
    ],
    has_optional => [
        array  => { is => 'SDM::Disk::Array', doc => 'Array identified by array name' },
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
    my $self = shift;
    my @args;
    local (*READER,*WRITER);
    sshopen2('root@' . $self->filer->name, *READER, *WRITER, "mmlsnsd -F") or die "Error calling ssh: $!";
    while (<READER>) {
        chomp;
        # Strip output header
        next until ($. > 3);
        if ($self->array) {
            next unless (/\s+$self->array->name\s+/);
        }
        last if ($#args == $self->count - 1);
        my $nsd = @{ [ split(/\s+/) ] }[2];
        push @args, $nsd;

    }
    close(READER);
    close(WRITER);
    if ($? == -1) {
         $self->error_message("failed to execute: $!");
         return;
    } elsif ($? & 127) {
         $self->error_message(sprintf("child died with signal %d, %s coredump", ($? & 127),  ($? & 128) ? 'with' : 'without'));
         return;
    } else {
         $self->warning_message(sprintf("child exited with value %d\n", $? >> 8));
         return if ($? >> 8);
    }

    my $arg = join(";",@args);
    # FIXME: Note hardcoded convention /vol + /name
    my $cmd = "echo mmcrfs /vol/$self->volume $self->volume $arg -A yes";
    #my $response = $self->_ask_user_question("Ok to run [Y|n]: $cmd",'Y','n');
    #return unless ($response =~ /y/i);
    sshopen2('root@' . $self->filer->name, *READER, *WRITER, $cmd) or die "Error calling ssh: $!";
    close(READER);
    close(WRITER);
    if ($? == -1) {
         $self->error_message("failed to execute: $!");
         return;
    } elsif ($? & 127) {
         $self->error_message(sprintf("child died with signal %d, %s coredump", ($? & 127),  ($? & 128) ? 'with' : 'without'));
         return;
    } else {
         $self->warning_message(sprintf("child exited with value %d\n", $? >> 8));
         return;
    }
    return 1;
}

1;
