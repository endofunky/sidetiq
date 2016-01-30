require_relative 'helper'

class TestHistory < Sidetiq::TestCase
  class HistoryWorker
    include Sidekiq::Worker
    include Sidetiq::Schedulable
  end

  def test_success
    middlewared do; end

    entry = Sidekiq.redis do |redis|
      redis.lrange('sidetiq:TestHistory::HistoryWorker:history', 0, -1)
    end

    actual = Sidekiq.load_json(entry[0]).symbolize_keys

    assert_equal 'success', actual[:status]

    assert_empty actual[:error]
    assert_empty actual[:backtrace]
    assert_empty actual[:exception]

    refute_empty actual[:node]
    refute_empty actual[:timestamp]
    assert actual[:runtime] > 0
  end

  def test_failure
    begin
      middlewared do
        raise StandardError.new("failed")
      end
    rescue
    end

    entry = Sidekiq.redis do |redis|
      redis.lrange('sidetiq:TestHistory::HistoryWorker:history', 0, -1)
    end

    actual = Sidekiq.load_json(entry[0]).symbolize_keys

    assert_equal 'failure', actual[:status]

    assert_equal "failed", actual[:error]
    assert_equal "StandardError", actual[:exception]
    refute_empty actual[:backtrace]

    refute_empty actual[:node]
    refute_empty actual[:timestamp]
    assert actual[:runtime] > 0
  end

  def middlewared
    middleware = Sidetiq::Middleware::History.new

    middleware.call(HistoryWorker.new, {}, 'default') do
      yield
    end
  end
end

