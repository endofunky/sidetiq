require_relative 'helper'

class TestConfig < Sidetiq::TestCase
  def setup
    @saved = Sidetiq.config
    Sidetiq.config = Sidetiq::Config.new
  end

  def teardown
    Sidetiq.config = @saved
  end

  def test_configure
    Sidetiq.configure do |config|
      config.test = 42
    end

    assert_equal 42, Sidetiq.config.test
  end

  def test_configure_enqueue_jobs
    Sidetiq.configure do |config|
      config.enqueue_jobs = false
    end

    assert_equal false, Sidetiq.config.enqueue_jobs?
  end

  def test_configure_enqueue_jobs_callable
    Sidetiq.configure do |config|
      config.enqueue_jobs = ->{ false }
    end

    assert_equal false, Sidetiq.config.enqueue_jobs?
  end
end

