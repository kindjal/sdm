
use strict;
use warnings;

use English '-no_match_vars'; # for UID
use Test::More;
use Cwd;
use File::Basename;
use File::Find::Rule;

delete $ENV{BUILDRESULT};

my $resultdir = File::Basename::dirname File::Basename::dirname Cwd::abs_path __FILE__;

ok( -w $resultdir, "pbuilder result dir appears ready");
ok( defined $ENV{MYGPGKEY}, "MYGPGKEY is defined");

my @debs;
my @src = File::Find::Rule->directory()
            ->mindepth(2)
            ->maxdepth(2)
            ->name('debian')
            ->in('.');

print "Found packages: " . join(',', reverse sort @src) . ".\n";
foreach my $pkg (reverse sort @src) {
    ok( build_deb_package(package_name => $pkg, deb_upload_spool => '/gscuser/codesigner/incoming/lucid' ) == 1, "built $pkg");
}
done_testing();

sub build_deb_package {
    my (%build_params) = @_;
    my $package_name = $build_params{package_name};
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

    # .debs get signed and added to the apt repo via the codesigner role
    # Check that we can write there before we build.
    my $deb_upload_spool = "/gscuser/codesigner/incoming/lucid-genome-development/";
    if ( defined $build_params{deb_upload_spool} ) {
        $deb_upload_spool = $build_params{deb_upload_spool};
    }
    ok(-w "$deb_upload_spool", "$deb_upload_spool directory is writable") or return;

    # if BUILDHASH is set (by Jenkins) update changelog
    if ((defined $ENV{BUILDVERSION} and length $ENV{BUILDVERSION}) and
        (defined $ENV{BUILDRELEASE} and length $ENV{BUILDRELEASE}) and
        (defined $ENV{BUILDHASH}    and length $ENV{BUILDHASH})) {
        my $version = $ENV{BUILDVERSION};
        my $release = $ENV{BUILDRELEASE};
        my $buildhash = $ENV{BUILDHASH};
        my $rc = runcmd("/bin/bash -c \"pushd $package_dir && /usr/bin/debchange -v $version-$release-$buildhash \"Continuous build testing\" && popd\"");
    }

    # .debs get built via pdebuild, must be run on a build host, probably a slave to jenkins
    my $rc = runcmd("/bin/bash -c \"pushd $package_dir && /usr/bin/pdebuild --use-pdebuild-internal --logfile $resultdir/$source-build.log && fakeroot debian/rules clean && popd\"");
    ok($rc == 0, "built deb") or return;

    # Sign
    $rc = runcmd("/usr/bin/debsign -k$ENV{MYGPGKEY} $resultdir/${source}_*.changes");
    ok($rc == 0, "signed sources") or return;

    # Put all files, source, binary, and meta into spool.
    my %pkgs;
    my @bfiles;
    my @sfiles = glob("$resultdir/${source}_*");
    foreach my $package (@debs) {
        # Note that members of bfiles may also be in sfiles
        push @bfiles, glob("$resultdir/${package}_*");
    }
    # uniqify
    map { $pkgs{$_} = 1 } @sfiles;
    map { $pkgs{$_} = 1 } @bfiles;
    my @pkgfiles = keys %pkgs;

    deploy($deb_upload_spool, \@pkgfiles, remove_on_success => 1);
    runcmd("/bin/ls -lh $deb_upload_spool");

    # Clean up
    ok(unlink "$resultdir/$source-build.log", "cleaned build log") or return;
    return 1;
}

sub deploy {
    my ($dest, $packages, %opts) = @_;
    die "$dest directory is writable" unless -w "$dest";
    for my $p (@$packages) {
        my $gid = getgrnam("codesigner");
        chmod 0664, $p;
        chown $UID, $gid, $p;
        ok(runcmd("/bin/cp -a $p $dest") == 0, "deployed $p to $dest") or return;
        if ($opts{remove_on_success}) {
            unlink($p) or die "failed to remove $p after deploying";
        }
    }
    return 1;
}

sub runcmd {
    my $command = shift;
    system("$command");
    if ($? == -1) {
        print "failed to execute: $!\n";
    } elsif ($? & 127) {
        printf "child died with signal %d, %s coredump\n",
               ($? & 127),  ($? & 128) ? 'with' : 'without';
    } else {
        printf "child exited with value %d\n", $? >> 8;
    }
    return $? >> 8;
}

