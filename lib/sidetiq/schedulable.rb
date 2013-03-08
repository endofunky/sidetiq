module Sidetiq
  # Public: Mixin for Sidekiq::Worker classes.
  #
  # Examples
  #
  #   class MyWorker
  #       include Sidekiq::Worker
  #       include Sidetiq::Schedulable
  #
  #       # Daily at midnight
  #       tiq { daily }
  #     end
  module Schedulable
    module ClassMethods
      def last_scheduled_occurrence
        get_timestamp "last"
      end

      def next_scheduled_occurrence
        get_timestamp "next"
      end

      def tiq(&block) # :nodoc:
        clock = Sidetiq::Clock.instance
        clock.synchronize do
          clock.schedule_for(self).instance_eval(&block)
        end
      end

    private

      def get_timestamp(key)
        Sidekiq.redis do |redis|
          (redis.get("sidetiq:#{name}:#{key}") || -1).to_f
        end
      end
    end

    def self.included(klass) # :nodoc:
      klass.extend(Sidetiq::Schedulable::ClassMethods)
    end
  end
end
