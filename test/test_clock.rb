require_relative 'helper'

class TestClock < Sidetiq::TestCase
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

  def test_backfilling
    BackfillWorker.jobs.clear
    Sidetiq.stubs(:workers).returns([BackfillWorker])
    start = Sidetiq::Schedule.start_time

    BackfillWorker.stubs(:last_scheduled_occurrence).returns(start.to_f)
    clock.stubs(:gettime).returns(start)
    clock.tick

    BackfillWorker.jobs.clear

    clock.stubs(:gettime).returns(start + 86400 * 10 + 1)
    clock.tick
    assert_equal 10, BackfillWorker.jobs.length
  end

  def test_enqueues_jobs_by_schedule
    Sidetiq.stubs(:workers).returns([SimpleWorker])

    SimpleWorker.expects(:perform_at).times(10)

    10.times do |i|
      clock.stubs(:gettime).returns(Time.local(2011, 1, i + 1, 1))
      clock.tick
    end

    clock.stubs(:gettime).returns(Time.local(2011, 1, 10, 2))
    clock.tick
    clock.tick
    clock.tick
  end

  def test_enqueues_jobs_with_default_last_tick_arg_on_first_run
    time = Time.local(2011, 1, 1, 1, 30)

    clock.stubs(:gettime).returns(time, time + 3600)

    Sidetiq.stubs(:workers).returns([LastTickWorker])

    expected_first_tick = time + 1800
    expected_second_tick = expected_first_tick + 3600

    LastTickWorker.expects(:perform_at).with(expected_first_tick, -1).once
    LastTickWorker.expects(:perform_at).with(expected_second_tick,
      expected_first_tick.to_f).once

    clock.tick
    clock.tick
  end

  def test_enqueues_jobs_with_last_run_timestamp_and_next_run_timestamp
    time = Time.local(2011, 1, 1, 1, 30)

    clock.stubs(:gettime).returns(time, time + 3600)

    Sidetiq.stubs(:workers).returns([LastAndScheduledTicksWorker])

    expected_first_tick = time + 1800
    expected_second_tick = expected_first_tick + 3600

    LastAndScheduledTicksWorker.expects(:perform_at)
      .with(expected_first_tick, -1, expected_first_tick.to_f).once

    clock.tick

    LastAndScheduledTicksWorker.expects(:perform_at)
      .with(expected_second_tick, expected_first_tick.to_f,
      expected_second_tick.to_f).once

    clock.tick
  end

  def test_enqueues_jobs_with_last_run_timestamp_if_optional_argument
    time = Time.local(2011, 1, 1, 1, 30)

    clock.stubs(:gettime).returns(time, time + 3600)

    Sidetiq.stubs(:workers).returns([OptionalArgumentWorker])

    expected_first_tick = time + 1800

    OptionalArgumentWorker.expects(:perform_at)
      .with(expected_first_tick, -1).once
    clock.tick
  end

  def test_enqueues_jobs_correctly_for_splat_args_perform_methods
    time = Time.local(2011, 1, 1, 1, 30)

    clock.stubs(:gettime).returns(time, time + 3600)

    Sidetiq.stubs(:workers).returns([SplatArgsWorker])

    expected_first_tick = time + 1800

    SplatArgsWorker.expects(:perform_at)
      .with(expected_first_tick, -1, expected_first_tick.to_f).once
    clock.tick
  end

  def test_does_not_enqueues_jobs_unless_enqueue_jobs
    time = Time.local(2011, 1, 1, 1, 30)

    clock.stubs(:gettime).returns(time, time + 3600)

    Sidetiq.config.stubs(:enqueue_jobs?).returns(false)

    Sidetiq.stubs(:workers).returns([SimpleWorker])

    SimpleWorker.expects(:perform_at).never
    clock.tick
  end
end
