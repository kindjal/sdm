
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Test::More;
use Test::Output;
use Test::Exception;
use Data::Dumper;
$Data::Dumper::Indent = 1;
use File::Find::Rule;

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-service-lib.pm";

use_ok( 'SDM' );

my @desired_files;
foreach my $install (glob("$top/debian/ur-sdm-service*.install")) {
    open(FH,"<$install") or die "Failed to open $install: $!";
    my @lines = <FH>;
    close(FH);
    @lines = map { chomp; $_; } @lines;
    push @desired_files, @lines;
}

system("cd $top && fakeroot debian/rules clean install");
if ($? == -1) {
     print "failed to execute: $!\n";
} elsif ($? & 127) {
     printf "child died with signal %d, %s coredump\n",
         ($? & 127),  ($? & 128) ? 'with' : 'without';
} else {
     printf "child exited with value %d\n", $? >> 8;
}
ok( $? >> 8 == 0, "fake install ok") or die;

# for FILE in `find debian/tmp/ -type f | sed -e 's/debian\/tmp//'`; do grep -q  $FILE debian/ur-sdm-service*.install || echo $FILE ; done
# All files installed should show up in .install files
my $error = 0;
my $dir = "$top/debian/tmp";
my @files = File::Find::Rule->file()
                      ->in($dir);

# Check that all installed files are desired.
foreach my $file (@files) {
    chomp $file;
    $file =~ s|^\S+/debian/tmp||;
    next unless ($file);
    unless ( grep { /$file/ } @desired_files ) {
        warn "$file not found";
        $error = 1;
    }
}
ok( $error == 0, "installed files are desired" );

# Check that all desired files are installed
$error = 0;
foreach my $file (@desired_files) {
    chomp $file;
    if ( ! -f "$dir$file" ) {
        warn "$dir$file not installed: $!";
        $error = 1;
    }
}
ok( $error == 0, "desired files are installed" );

done_testing();
