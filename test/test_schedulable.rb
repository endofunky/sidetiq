require_relative 'helper'
require 'minitest/mock'

class TestSchedulable < Sidetiq::TestCase
  class FakeWorker
    include Sidetiq::Schedulable
  end

  def test_recurrence
    Sidekiq.stub(:server?, true) do
      Sidekiq.expects(:redis_pool).returns(Sidekiq::RedisConnection.create).at_least(1)

      FakeWorker.recurrence { hourly }
    end

    Sidekiq.stub(:server?, false) do
      Sidekiq.expects(:redis_pool).times(0)

      FakeWorker.recurrence { hourly }
    end
  end

  def test_rescheduling
    last_run = (Time.now - 100).to_f
    next_run = (Time.now + 100).to_f

    Sidekiq.redis do |redis|
      redis.set "sidetiq:test_schedulable:fake_worker:last", last_run
      redis.set "sidetiq:test_schedulable:fake_worker:next", next_run
    end

    assert FakeWorker.schedule_description == nil

    FakeWorker.schedule = nil
    FakeWorker.recurrence { minutely }

    assert FakeWorker.schedule_description == "Minutely"
    assert FakeWorker.last_scheduled_occurrence == -1.0
    assert FakeWorker.next_scheduled_occurrence == -1.0

    Sidekiq.redis do |redis|
      redis.set "sidetiq:test_schedulable:fake_worker:last", last_run
      redis.set "sidetiq:test_schedulable:fake_worker:next", next_run
    end

    FakeWorker.schedule = nil
    FakeWorker.recurrence { minutely }

    assert FakeWorker.schedule_description == "Minutely"
    assert FakeWorker.last_scheduled_occurrence == last_run
    assert FakeWorker.next_scheduled_occurrence == next_run

    FakeWorker.schedule = nil
    FakeWorker.recurrence { hourly }

    assert FakeWorker.schedule_description == "Hourly"
    assert FakeWorker.last_scheduled_occurrence == -1.0
    assert FakeWorker.next_scheduled_occurrence == -1.0
  end
end
