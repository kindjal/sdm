
package SDM::Service::WebApp::Resource;

use Plack::Builder;
use above 'SDM';

my $res_path = SDM::Service::WebApp->res_path;

builder {
    enable "Plack::Middleware::Static",
      path => qr{},
      root => $res_path;

    $app;
};
