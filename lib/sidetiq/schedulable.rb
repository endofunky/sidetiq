module Sidetiq
  # Public: Mixin for Sidekiq::Worker classes.
  #
  # Examples
  #
  #   class MyWorker
  #     include Sidekiq::Worker
  #     include Sidetiq::Schedulable
  #
  #     # Daily at midnight
  #     recurrence { daily }
  #   end
  module Schedulable
    module ClassMethods
      # Public: Returns a Float timestamp of the last scheduled run.
      def last_scheduled_occurrence
        get_timestamp "last"
      end

      # Public: Returns a Float timestamp of the next scheduled run.
      def next_scheduled_occurrence
        get_timestamp "next"
      end

      def tiq(*args, &block) # :nodoc:
        Sidetiq.logger.warn "DEPRECATION WARNING: Sidetiq::Schedulable#tiq" <<
          " is deprecated and will be removed. Use" <<
          " Sidetiq::Schedulable#recurrence instead."
        recurrence(*args, &block)
      end

      def recurrence(options = {}, &block) # :nodoc:
        clock = Sidetiq::Clock.instance
        clock.mon_synchronize do
          schedule = clock.schedule_for(self)
          schedule.instance_eval(&block)
          schedule.set_options(options)
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

