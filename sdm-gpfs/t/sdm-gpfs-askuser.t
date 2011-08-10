
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use SDM;

use Test::More;
use Test::Output;
use Test::Exception;

my $obj = SDM::Command::Base->new();
#    if ($self->_ask_user_question( "Ok to run: $cmd", 0) eq 'y') {

done_testing();
