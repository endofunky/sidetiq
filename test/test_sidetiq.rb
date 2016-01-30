require_relative 'helper'

class TestSidetiq < Sidetiq::TestCase
  def before
    Sidetiq::Schedule.stubs(:beginning_of_times).returns(Time.new(2014, 1, 1))
  end

  def test_schedules
    schedules = Sidetiq.schedules
    assert_includes schedules, ScheduledWorker.schedule
    assert_includes schedules, BackfillWorker.schedule
    assert_kind_of Sidetiq::Schedule, ScheduledWorker.schedule
    assert_kind_of Sidetiq::Schedule, BackfillWorker.schedule
  end

  def test_workers
    workers = Sidetiq.workers
    assert_includes workers, ScheduledWorker
    assert_includes workers, BackfillWorker
  end

  def test_scheduled
    client = Sidekiq::Client.new
    SimpleWorker.perform_at(Time.local(2011, 1, 1, 1))
    hash = SimpleWorker.jobs.first
    client.push_old(hash.merge('at' => hash['created_at']))
    scheduled = Sidetiq.scheduled
    assert_kind_of Array, scheduled
    assert_kind_of Sidekiq::SortedEntry, scheduled.first
    assert_equal 1, scheduled.length
  end

  def test_scheduled_on_empty_set
    assert_equal 0, Sidetiq.scheduled.length
  end

  def test_scheduled_given_arguments
    client = Sidekiq::Client.new
    SimpleWorker.perform_at(Time.local(2011, 1, 1, 1))
    hash = SimpleWorker.jobs.first
    client.push_old(hash.merge('at' => hash['created_at']))
    assert_equal 1, Sidetiq.scheduled(SimpleWorker).length
    assert_equal 0, Sidetiq.scheduled(ScheduledWorker).length
    assert_equal 1, Sidetiq.scheduled('SimpleWorker').length
    assert_equal 0, Sidetiq.scheduled('ScheduledWorker').length
  end

  def test_scheduled_yields_each_job
    client = Sidekiq::Client.new
    SimpleWorker.perform_at(Time.local(2011, 1, 1, 1))
    hash = SimpleWorker.jobs.first
    client.push_old(hash.merge('at' => hash['created_at']))
    ScheduledWorker.perform_at(Time.local(2011, 1, 1, 1))
    hash = ScheduledWorker.jobs.first
    client.push_old(hash.merge('at' => hash['created_at']))
    jobs = []
    Sidetiq.scheduled { |job| jobs << job }
    assert_equal 2, jobs.length
    jobs = []
    Sidetiq.scheduled(SimpleWorker) { |job| jobs << job }
    assert_equal 1, jobs.length
    jobs = []
    Sidetiq.scheduled('ScheduledWorker') { |job| jobs << job }
    assert_equal 1, jobs.length
  end

  def test_scheduled_with_invalid_class
    assert_raises(NameError) do
      Sidetiq.scheduled('Foobar')
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
    assert_equal 1, Sidetiq.retries('SimpleWorker').length
    assert_equal 0, Sidetiq.retries('ScheduledWorker').length
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
    Sidetiq.retries('ScheduledWorker') { |job| jobs << job }
    assert_equal 1, jobs.length
  end

  def test_retries_with_invalid_class
    assert_raises(NameError) do
      Sidetiq.retries('Foobar')
    end
  end
end
