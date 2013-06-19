if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start { add_filter "/test/" }
end

require 'minitest/autorun'
require 'mocha/setup'
require 'rack/test'

require 'sidekiq'
require 'sidekiq/testing'

require 'sidetiq'
require 'sidetiq/web'

# Keep the test output clean.
Sidetiq.logger = Logger.new(nil)

Dir[File.join(File.dirname(__FILE__), 'fixtures/**/*.rb')].each do |fixture|
  require fixture
end

class Sidekiq::Client
  # Sidekiq testing helper now overwrites raw_push so we need to use
  # raw_push_old below to keep tests as is.
  # https://github.com/mperham/sidekiq/blob/v2.12.4/lib/sidekiq/client.rb#L39
  def self.push_old(item)
    normed = normalize_item(item)
    payload = process_single(item['class'], normed)

    pushed = false
    pushed = raw_push_old([payload]) if payload
    pushed ? payload['jid'] : nil
  end
end

class Sidetiq::TestCase < MiniTest::Unit::TestCase
  def setup
    Sidekiq.redis { |r| r.flushall }
  end

  def clock
    @clock ||= Sidetiq::Clock.instance
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

