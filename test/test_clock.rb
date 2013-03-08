require_relative 'helper'

class TestClock < Sidetiq::TestCase
  class FakeWorker
    def perform
    end
  end

  def test_delegates_to_instance
    Sidetiq::Clock.instance.expects(:foo).once
    Sidetiq::Clock.foo
  end

  def test_start_stop
    refute clock.ticking?
    assert_nil clock.thread

    clock.start!
    Thread.pass
    sleep 0.01

    assert clock.ticking?
    assert_kind_of Thread, clock.thread

    clock.stop!
    Thread.pass
    sleep 0.01

    refute clock.ticking?
    refute clock.thread.alive?
  end

  def test_gettime_seconds
    assert_equal clock.gettime.tv_sec, Time.now.tv_sec
  end

  def test_gettime_nsec
    refute_nil clock.gettime.tv_nsec
  end

  def test_gettime_utc
    refute clock.gettime.utc?
    Sidetiq.config.utc = true
    assert clock.gettime.utc?
    Sidetiq.config.utc = false
  end

  def test_enqueues_jobs_by_schedule
    schedule = Sidetiq::Schedule.new(Sidetiq::Clock::START_TIME)
    schedule.daily

    clock.stubs(:schedules).returns(FakeWorker => schedule)

    FakeWorker.expects(:perform_at).times(10)

    10.times do |i|
      clock.stubs(:gettime).returns(Time.local(2011, 1, i + 1, 1))
      clock.tick
    end

    clock.stubs(:gettime).returns(Time.local(2011, 1, 10, 2))
    clock.tick
    clock.tick
    clock.tick
  end

  class LastTickWorker
    def perform last_tick
    end
  end

  def test_enqueues_jobs_with_default_last_tick_arg_on_first_run
    schedule = Sidetiq::Schedule.new(Sidetiq::Clock::START_TIME)
    schedule.hourly

    time = Time.local(2011, 1, 1, 1, 30)

    clock.stubs(:gettime).returns(time, time + 3600)
    clock.stubs(:schedules).returns(LastTickWorker => schedule)

    expected_first_tick = time + 1800
    expected_second_tick = expected_first_tick + 3600

    LastTickWorker.expects(:perform_at).with(expected_first_tick, -1).once
    LastTickWorker.expects(:perform_at).with(expected_second_tick, expected_first_tick.to_f).once

    clock.tick
    clock.tick
  end

  class LastAndScheduledTicksWorker
    def perform last_tick, scheduled_tick
    end
  end

  def test_enqueues_jobs_with_last_run_timestamp_and_next_run_timestamp
    schedule = Sidetiq::Schedule.new(Sidetiq::Clock::START_TIME)
    schedule.hourly

    time = Time.local(2011, 1, 1, 1, 30)

    clock.stubs(:gettime).returns(time, time + 3600)
    clock.stubs(:schedules).returns(LastAndScheduledTicksWorker => schedule)

    expected_first_tick = time + 1800
    expected_second_tick = expected_first_tick + 3600

    LastAndScheduledTicksWorker.expects(:perform_at).with(expected_first_tick, -1, expected_first_tick.to_f).once
    clock.tick

    LastAndScheduledTicksWorker.expects(:perform_at).with(expected_second_tick, expected_first_tick.to_f, expected_second_tick.to_f).once
    clock.tick
  end

  class SplatArgsWorker
    def perform arg1, *args
    end
  end

  def test_enqueues_jobs_correctly_for_splat_args_perform_methods
    schedule = Sidetiq::Schedule.new(Sidetiq::Clock::START_TIME)
    schedule.hourly

    time = Time.local(2011, 1, 1, 1, 30)

    clock.stubs(:gettime).returns(time, time + 3600)
    clock.stubs(:schedules).returns(SplatArgsWorker => schedule)

    expected_first_tick = time + 1800

    SplatArgsWorker.expects(:perform_at).with(expected_first_tick, -1, expected_first_tick.to_f).once
    clock.tick
  end
end
