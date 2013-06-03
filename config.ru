require './spanel'
use Rack::Static, :urls => ["/css","/img","/js"], :root => "public"
run	Symbiosis::SPanel::App
