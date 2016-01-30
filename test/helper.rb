ENV['RACK_ENV'] = 'test'
if RUBY_PLATFORM != "java"
  require 'coveralls'
  Coveralls.wear!
end

require 'sidekiq'
require 'sidekiq/testing'

require 'minitest'
require 'mocha/setup'
require 'rack/test'

require 'sidetiq'
require 'sidetiq/web'

module Sidekiq
  def self.server?
    true
  end
end

class Sidetiq::Supervisor
  def self.clock
    @clock ||= Sidetiq::Clock.new
  end

  def self.handler
    Sidetiq::Handler.new
  end
end

# Keep the test output clean.
Sidetiq.logger = Logger.new(nil)

Dir[File.join(File.dirname(__FILE__), 'fixtures/**/*.rb')].each do |fixture|
  require fixture
end

class Sidekiq::Client
  # Sidekiq testing helper now overwrites raw_push so we need to use
  # raw_push_old below to keep tests as is.
  # https://github.com/mperham/sidekiq/blob/master/lib/sidekiq/testing.rb
  def push_old(item)
    normed = normalize_item(item)
    payload = process_single(item['class'], normed)

    pushed = false
    pushed = self.__send__(:raw_push_real, [payload]) if payload
    pushed ? payload['jid'] : nil
  end
end

class Sidetiq::TestCase < MiniTest::Test
  def setup
    Sidekiq.redis { |r| r.flushall }
  end

  def clock
    Sidetiq.clock
  end

  # Blatantly stolen from Sidekiq's test suite.
  def add_retry(worker = 'SimpleWorker', jid = 'bob', at = Time.now.to_f)
    payload = Sidekiq.dump_json('class' => worker,
      'args' => [], 'queue' => 'default', 'jid' => jid,
      'retry_count' => 2, 'failed_at' => Time.now.utc)

    Sidekiq.redis do |conn|
      conn.zadd('retry', at.to_s, payload)
    end
  end
end

# Override Celluloid's at_exit hook manually.
at_exit {
  exit Minitest.run(ARGV) || false
}
