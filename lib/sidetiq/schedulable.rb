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
    extend SubclassTracking

    module ClassMethods
      include SubclassTracking

      attr_writer :schedule

      # Public: Returns a Float timestamp of the last scheduled run.
      def last_scheduled_occurrence
        get_timestamp "last"
      end

      # Public: Returns the Sidetiq::Schedule for this worker.
      def schedule
        @schedule ||= Sidetiq::Schedule.new
      end

      # Public: Returns a Float timestamp of the next scheduled run.
      def next_scheduled_occurrence
        get_timestamp "next"
      end

      def recurrence(options = {}, &block) # :nodoc:
        schedule.instance_eval(&block)
        schedule.set_options(options)
      end

      private

      def get_timestamp(key)
        Sidekiq.redis do |redis|
          (redis.get("sidetiq:#{Sidetiq.namespace(name)}:#{key}") || -1).to_f
        end
      end
    end

    def self.included(klass) # :nodoc:
      super

      klass.extend(Sidetiq::Schedulable::ClassMethods)
      klass.extend(Sidetiq::SubclassTracking)
      subclasses << klass
    end
  end
end

