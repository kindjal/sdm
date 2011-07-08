
use strict;
use warnings;

use English '-no_match_vars'; # for UID
use Test::More;
use Cwd;
use File::Basename;
use File::Find::Rule;

delete $ENV{BUILDRESULT};

my $resultdir = File::Basename::dirname File::Basename::dirname Cwd::abs_path __FILE__;

ok( -w $resultdir, "pbuilder result dir appears ready") or diag("$resultdir not writable");
ok( defined $ENV{MYGPGKEY}, "MYGPGKEY is defined") or diag("no gpg key in ENV");

my @debs;
my @src = File::Find::Rule->directory()
            ->mindepth(2)
            ->maxdepth(2)
            ->name(qr/^debian$/)
            ->in('.');

print "Found packages: " . join(',', reverse sort @src) . ".\n";
foreach my $pkg (reverse sort @src) {
    ok( build_deb_package(package_name => $pkg, deb_upload_spool => '/gscuser/codesigner/incoming/lucid' ) == 1, "built $pkg");
}
done_testing();

sub build_deb_package {
    my (%params) = @_;
    my $package_name = $params{package_name};
    my $package_dir = File::Basename::dirname $package_name;

    # A single source tree may have multiple source and binary packages produced.
    my $source;
    open(FH,"<$package_dir/debian/control") or die "Cannot open $package_dir/debian/control";
    while(<FH>) {
        if (/^Source:/) {
            $source = pop @{ [ split /\s+/, $_ ] };
        }
        if (/^Package:/) {
            push @debs, pop @{ [ split /\s+/, $_ ] };
        }
    }
    close(FH);
    die "Cannot determine package Source name" unless ($source);
    die "Cannot determine target Package names" unless (@debs);

    # .debs get signed and added to the apt repo via the codesigner role
    # Check that we can write there before we build.
    die "Upload spool unset" unless ( $params{deb_upload_spool} );
    my $deb_upload_spool = $params{deb_upload_spool};

    die "upload spool $deb_upload_spool is not writable" unless (-w "$deb_upload_spool");

    my $version;
    my $release;
    my $buildhash;

    # if BUILDHASH is set (by Jenkins) update changelog, build but don't publish.
    if ((defined $ENV{BUILDVERSION} and length $ENV{BUILDVERSION}) and
        (defined $ENV{BUILDRELEASE} and length $ENV{BUILDRELEASE}) and
        (defined $ENV{BUILDHASH}    and length $ENV{BUILDHASH})) {
        $version = $ENV{BUILDVERSION};
        $release = $ENV{BUILDRELEASE};
        $buildhash = $ENV{BUILDHASH};
        my $rc = runcmd("/usr/bin/debchange -l$package_dir/debian/changelog -D unstable -v $version-$release-$buildhash Jenkins build testing");
        ok($rc == 0, "updated changelog") or diag("failed to update changelog");
    } else {
        # Else read changelog
        open(CMD,"/usr/bin/dpkg-parsechangelog -l$package_dir/debian/changelog |") or die "Cannot execute dpkg-parsechangelog: $!";
        while(<CMD>) {
            if (/^(\S+): (.*)$/) {
                $version = $2 if ($1 eq "Version");
            }
        }
        close(CMD);
        if ($version) {
            ($version,$release) = split("-",$version,2);
        } else {
            die "cannot parse version from changelog $package_dir/debian/changelog";
        }
    }

    # .debs get built via pdebuild, must be run on a build host, probably a slave to jenkins
    my $pwd = $ENV{PWD};
    chdir $package_dir;
    my $rc;
    eval {
        $rc = runcmd("/usr/bin/pdebuild --auto-debsign --debsign-k $ENV{MYGPGKEY} --use-pdebuild-internal --logfile $resultdir/$source-build.log && fakeroot debian/rules clean");
    };
    my @errs;
    open(LOG,"egrep \"( error| failure)\" $resultdir/$source-build.log |") or die "can't open log file: $!";
    while (<LOG>) {
        chomp;
        push @errs, $_;
    }
    close(LOG);
    chdir $pwd;
    ok($rc == 0, "built deb") or diag("failed to build deb:\n" . join("\n",@errs));

    # Sign changes
    #$rc = runcmd("/usr/bin/debsign -k$ENV{MYGPGKEY} $resultdir/${source}_${version}*.changes");
    #ok($rc == 0, "signed sources") or return 0;

    # Put all files, source, binary, and meta into spool.
    my %pkgs;
    my @bfiles;
    my @sfiles = glob("$resultdir/${source}_${version}*");
    foreach my $package (@debs) {
        # Note that members of bfiles may also be in sfiles
        push @bfiles, glob("$resultdir/${package}_${version}*");
    }
    # uniqify
    map { $pkgs{$_} = 1 } @sfiles;
    map { $pkgs{$_} = 1 } @bfiles;
    my @pkgfiles = keys %pkgs;

    if ($buildhash) {
        # Only deploy tagged builds
        foreach my $pkg (@pkgfiles) {
            ok( unlink $pkg, "removed intermediate deb");
        }
    } else {
        deploy($deb_upload_spool, \@pkgfiles, remove_on_success => 1);
    }

    # Clean up
    ok(unlink "$resultdir/$source-build.log", "cleaned build log") or return 0;
    return 1;
}

sub deploy {
    my ($dest, $packages, %opts) = @_;
    die "$dest directory is writable" unless -w "$dest";
    for my $p (@$packages) {
        my $gid = getgrnam("codesigner");
        chmod 0664, $p;
        chown $UID, $gid, $p;
        ok(runcmd("/bin/cp $p $dest") == 0, "deployed $p to $dest") or return;
        if ($opts{remove_on_success}) {
            unlink($p) or die "failed to remove $p after deploying";
        }
    }
    return 1;
}

sub runcmd {
    my $command = shift;
    printf "runcmd: $command\n";
    system($command);
    if ($? == -1) {
        die "failed to execute: $!";
    } elsif ($? & 127) {
        my $msg = sprintf "child died with signal %d, %s coredump\n",
               ($? & 127),  ($? & 128) ? 'with' : 'without';
        die $msg;
    }
    my $rc = $? >> 8;
    die "command exited $rc" if ($rc);
    return 0;
}

