require_relative 'helper'

class TestSchedule < Sidetiq::TestCase
  def test_method_missing
    sched = Sidetiq::Schedule.new
    sched.daily.minute_of_hour(15).hour_of_day(9)
    assert_equal "Daily on the 15th minute of the hour on the 9th hour of the day", sched.to_s
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
    assert_equal(Time.utc(Time.now.year, Time.now.month, Time.now.day), Sidetiq::Schedule.new.start_time)
  ensure
    Sidetiq.config.utc = false
  end
end
