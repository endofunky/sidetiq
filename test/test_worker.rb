require_relative 'helper'

class TestWorker < Sidetiq::TestCase
  class FakeWorker
    include Sidetiq::Schedulable
  end

  def test_timestamps_for_new_worker
    assert FakeWorker.last_scheduled_occurrence == -1
    assert FakeWorker.next_scheduled_occurrence == -1
  end

  def test_timestamps_for_existing_worker
    last_run = (Time.now - 100).to_f
    next_run = (Time.now + 100).to_f

    Sidekiq.redis do |redis|
      redis.set "sidetiq:TestWorker::FakeWorker:last", last_run
      redis.set "sidetiq:TestWorker::FakeWorker:next", next_run
    end

    assert FakeWorker.last_scheduled_occurrence == last_run
    assert FakeWorker.next_scheduled_occurrence == next_run
  end

  def test_active_option
    assert FakeWorker.active?

    Sidekiq.redis do |redis|
      redis.set 'sidetiq:TestWorker::FakeWorker:active', 0
    end

    refute FakeWorker.active?

    Sidekiq.redis do |redis|
      redis.set 'sidetiq:TestWorker::FakeWorker:active', 1
    end

    assert FakeWorker.active?
  end

  def test_options
    assert BackfillWorker.schedule.backfill?
  end
end
