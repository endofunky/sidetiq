module Sidetiq
  module Lock
    class Redis
      include Logging

      attr_reader :key, :timeout

      def self.all
        Sidekiq.redis do |redis|
          redis.keys("sidetiq:*:lock").map do |key|
            new(key)
          end
        end
      end

      def initialize(key, timeout = Sidetiq.config.lock_expire)
        @key = extract_key(key)
        @timeout = timeout
      end

      def synchronize
        Sidekiq.redis do |redis|
          acquired = lock

          if acquired
            debug "Lock: #{key}"

            begin
              yield redis
            ensure
              unlock
              debug "Unlock: #{key}"
            end
          end
        end
      end

      def stale?
        pttl = meta_data.pttl

        # Consider PTTL of -1 (never set) and larger than the
        # configured lock_expire as invalid. Locks with timestamps
        # older than 1 minute are also considered stale.
        pttl < 0 || pttl >= Sidetiq.config.lock_expire ||
          meta_data.timestamp < (Sidetiq.clock.gettime.to_i - 60)
      end

      def meta_data
        @meta_data ||= Sidekiq.redis do |redis|
          MetaData.from_json(redis.get(key))
        end
      end

      def lock
        Sidekiq.redis do |redis|
          acquired = false

          watch(redis, key) do
            unless redis.exists(key)
              acquired = !!redis.multi do |multi|
                meta = MetaData.for_new_lock(key)
                multi.psetex(key, timeout, meta.to_json)
              end
            end
          end

          acquired
        end
      end

      def unlock
        Sidekiq.redis do |redis|
          watch(redis, key) do
            if meta_data.owner == Sidetiq::Lock::MetaData::OWNER
              redis.multi do |multi|
                multi.del(key)
              end

              true
            else
              false
            end
          end
        end
      end

      def unlock!
        Sidekiq.redis do |redis|
          redis.del(key)
        end
      end

      private

      def extract_key(key)
        case key
        when Class
          "sidetiq:#{Sidetiq.namespace(key)}:lock"
        when String
          key.match(/sidetiq:(.+):lock/) ? key : "sidetiq:#{key}:lock"
        end
      end

      def watch(redis, *args)
        redis.watch(*args)

        begin
          yield
        ensure
          redis.unwatch
        end
      end
    end
  end
end
