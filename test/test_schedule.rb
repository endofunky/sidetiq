require_relative 'helper'

class TestSchedule < Sidetiq::TestCase
  def test_method_missing
    sched = Sidetiq::Schedule.new
    sched.daily
    assert_equal "Daily", sched.to_s
  end

  def test_schedule_next?
    sched = Sidetiq::Schedule.new

    sched.daily

    assert sched.schedule_next?(Time.now + (24 * 60 * 60))
    refute sched.schedule_next?(Time.now + (24 * 60 * 60))
    assert sched.schedule_next?(Time.now + (2 * 24 * 60 * 60))
    refute sched.schedule_next?(Time.now + (2 * 24 * 60 * 60))
  end

  def test_backfill
    sched = Sidetiq::Schedule.new
    refute sched.backfill?
    sched.backfill = true
    assert sched.backfill?
  end

  def test_set_options
    sched = Sidetiq::Schedule.new

    sched.set_options(backfill: true)
    assert sched.backfill?

    sched.set_options(backfill: false)
    refute sched.backfill?
  end

  def test_use_utc
    Sidetiq.config.utc = true
    Sidetiq::Schedule.stubs(:beginning_of_times).returns(Time.new(2014, 1, 1))
    assert_equal(Time.utc(2014, 01, 01), Sidetiq::Schedule.start_time)
  ensure
    Sidetiq.config.utc = false
  end
end

