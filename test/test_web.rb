require_relative 'helper'

class TestWeb < Sidetiq::TestCase
  include Rack::Test::Methods

  def app
    Sidekiq::Web
  end

  def host
    last_request.host
  end

  def setup
    super
    ScheduledWorker.jobs.clear
    Sidetiq.stubs(:workers).returns([ScheduledWorker])
  end

  def test_home_tab
    get '/'
    assert_equal 200, last_response.status
    assert_match /Sidekiq/, last_response.body
    assert_match /Sidetiq/, last_response.body
  end

  def test_sidetiq_page
    get '/sidetiq'
    assert_equal 200, last_response.status

    Sidetiq.workers.each do |worker|
      assert_match /#{worker.name}/, last_response.body
      assert_match /#{worker.get_sidekiq_options['queue']}/, last_response.body
    end
  end

  def test_locks_page
    get "/sidetiq/locks"
    assert_equal 200, last_response.status
  end

  def test_history_page
    get "/sidetiq/ScheduledWorker/history"
    assert_equal 200, last_response.status
  end

  def test_schedule_page
    get "/sidetiq/ScheduledWorker/schedule"
    assert_equal 200, last_response.status
    schedule = ScheduledWorker.schedule

    schedule.recurrence_rules.each do |rule|
      assert_match /#{rule.to_s}/, last_response.body
    end

    schedule.exception_rules.each do |rule|
      assert_match /#{rule.to_s}/, last_response.body
    end

    schedule.next_occurrences(10).each do |time|
      assert_match /#{time.getutc.to_s}/, last_response.body
    end
  end

  def test_trigger
    post "/sidetiq/ScheduledWorker/trigger"
    assert_equal 302, last_response.status
    assert_equal "http://#{host}/sidetiq", last_response.location
    assert_equal 1, ScheduledWorker.jobs.size
  end

  def test_deactivate
    Sidekiq.redis do |redis|
      redis.set 'sidetiq:ScheduledWorker:active', '1'
    end

    post '/sidetiq/ScheduledWorker/deactivate'
    assert_equal 302, last_response.status
    assert_equal "http://#{host}/sidetiq", last_response.location
    refute ScheduledWorker.active?
  end

  def test_activate
    Sidekiq.redis do |redis|
      redis.set 'sidetiq:ScheduledWorker:active', '0'
    end

    post '/sidetiq/ScheduledWorker/activate'
    assert_equal 302, last_response.status
    assert_equal "http://#{host}/sidetiq", last_response.location
    assert ScheduledWorker.active?
  end

  def test_unlock
    Sidekiq.redis do |redis|
      redis.set("sidetiq:Foo:lock", 1)
    end

    post "/sidetiq/Foo/unlock"
    assert_equal 302, last_response.status
    assert_equal "http://#{host}/sidetiq/locks", last_response.location

    Sidekiq.redis do |redis|
      assert_nil redis.get("sidetiq:Foo:lock")
    end
  end
end
