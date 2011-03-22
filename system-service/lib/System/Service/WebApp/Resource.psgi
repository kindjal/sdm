
package System::Service::WebApp::Resource;

use Plack::Builder;
use above 'System';

my $res_path = System::Service::WebApp->res_path;

builder {
    enable "Plack::Middleware::Static",
      path => qr{},
      root => $res_path;

    $app;
};
