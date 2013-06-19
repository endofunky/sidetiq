require_relative 'helper'

class TestSidetiq < Sidetiq::TestCase
  def test_schedules
    schedules = Sidetiq.schedules

    assert_equal 2, schedules.length

    assert_includes schedules.keys, ScheduledWorker
    assert_includes schedules.keys, BackfillWorker

    assert_kind_of Sidetiq::Schedule, schedules[ScheduledWorker]
    assert_kind_of Sidetiq::Schedule, schedules[BackfillWorker]
  end

  def test_workers
    workers = Sidetiq.workers

    assert_includes workers, ScheduledWorker
    assert_includes workers, BackfillWorker
    assert_equal 2, workers.length
  end

  def test_scheduled
    SimpleWorker.perform_at(Time.local(2011, 1, 1, 1))
    Sidekiq::Client.push_old(SimpleWorker.jobs.first)

    scheduled = Sidetiq.scheduled

    assert_kind_of Array, scheduled
    assert_kind_of Sidekiq::SortedEntry, scheduled.first
    assert_equal 1, scheduled.length
  end

  def test_scheduled_on_empty_set
    assert_equal 0, Sidetiq.scheduled.length
  end

  def test_scheduled_given_arguments
    SimpleWorker.perform_at(Time.local(2011, 1, 1, 1))
    Sidekiq::Client.push_old(SimpleWorker.jobs.first)

    assert_equal 1, Sidetiq.scheduled(SimpleWorker).length
    assert_equal 0, Sidetiq.scheduled(ScheduledWorker).length

    assert_equal 1, Sidetiq.scheduled("SimpleWorker").length
    assert_equal 0, Sidetiq.scheduled("ScheduledWorker").length
  end

  def test_scheduled_yields_each_job
    SimpleWorker.perform_at(Time.local(2011, 1, 1, 1))
    Sidekiq::Client.push_old(SimpleWorker.jobs.first)

    ScheduledWorker.perform_at(Time.local(2011, 1, 1, 1))
    Sidekiq::Client.push_old(ScheduledWorker.jobs.first)

    jobs = []
    Sidetiq.scheduled { |job| jobs << job }
    assert_equal 2, jobs.length

    jobs = []
    Sidetiq.scheduled(SimpleWorker) { |job| jobs << job }
    assert_equal 1, jobs.length

    jobs = []
    Sidetiq.scheduled("ScheduledWorker") { |job| jobs << job }
    assert_equal 1, jobs.length
  end

  def test_scheduled_with_invalid_class
    assert_raises(NameError) do
      Sidetiq.scheduled("Foobar")
    end
  end

  def test_retries
    add_retry('SimpleWorker', 'foo')
    add_retry('ScheduledWorker', 'bar')

    retries = Sidetiq.retries

    assert_kind_of Array, retries
    assert_kind_of Sidekiq::SortedEntry, retries[0]
    assert_kind_of Sidekiq::SortedEntry, retries[1]
    assert_equal 2, retries.length
  end

  def test_retries_on_empty_set
    assert_equal 0, Sidetiq.retries.length
  end

  def test_retries_given_arguments
    add_retry('SimpleWorker', 'foo')

    assert_equal 1, Sidetiq.retries(SimpleWorker).length
    assert_equal 0, Sidetiq.retries(ScheduledWorker).length

    assert_equal 1, Sidetiq.retries("SimpleWorker").length
    assert_equal 0, Sidetiq.retries("ScheduledWorker").length
  end

  def test_retries_yields_each_job
    add_retry('SimpleWorker', 'foo')
    add_retry('ScheduledWorker', 'foo')

    jobs = []
    Sidetiq.retries { |job| jobs << job }
    assert_equal 2, jobs.length

    jobs = []
    Sidetiq.retries(SimpleWorker) { |job| jobs << job }
    assert_equal 1, jobs.length

    jobs = []
    Sidetiq.retries("ScheduledWorker") { |job| jobs << job }
    assert_equal 1, jobs.length
  end

  def test_retries_with_invalid_class
    assert_raises(NameError) do
      Sidetiq.retries("Foobar")
    end
  end
end

