require_relative 'helper'

class TestLockRedis < Sidetiq::TestCase
  def test_locking
    lock_name = SecureRandom.hex(8)
    key = SecureRandom.hex(8)
    Sidekiq.redis do |redis|
      redis.set(key, 0)
      5.times.map do
        Thread.start do
          locked(lock_name) do |r|
            sleep 0.1
            r.incr(key)
          end
        end
      end.each(&:join)
      assert_equal "1", redis.get(key)
    end
  end

  def test_all
    Sidekiq.redis do |redis|
      redis.set("sidetiq:Foobar:lock", 1)
    end

    locks = Sidetiq::Lock::Redis.all

    assert_equal "sidetiq:Foobar:lock", locks.first.key
  end

  def test_unlock!
    Sidekiq.redis do |redis|
      redis.set("sidetiq:Foobar:lock", 1)

      Sidetiq::Lock::Redis.new("Foobar").unlock!

      assert_nil redis.get("sidetiq:Foobar:lock")
    end
  end

  def test_lock_sets_correct_meta_data
    key = SecureRandom.hex(8)
    internal_key = "sidetiq:#{key}:lock"

    locked(key) do |redis|
      json = redis.get(internal_key)
      md = Sidetiq::Lock::MetaData.from_json(json)

      assert_equal Sidetiq::Lock::MetaData::OWNER, md.owner
      assert_equal internal_key, md.key
    end
  end


  def test_extract_key_with_custom_queue
    lock_redis = ::Sidetiq::Lock::Redis.new(SimpleWorkerWithQueue)
    assert_equal "sidetiq:simpleworkerwithqueue_test1234:lock", lock_redis.instance_variable_get(:@key)
  end

  def locked(lock_name)
    Sidetiq::Lock::Redis.new(lock_name).synchronize do |redis|
      yield redis
    end
  end
end
