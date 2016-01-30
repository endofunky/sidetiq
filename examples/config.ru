require 'sidekiq'
require 'sidetiq'

require 'sidekiq/web'
require 'sidetiq/web'

require './workers/simple.rb'
require './workers/failing.rb'

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end

use Rack::Session::Cookie, :secret => "some unique secret string here"

run Sidekiq::Web
