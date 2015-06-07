module Sidetiq
  # Public: Recurrence schedule.
  class Schedule
    # :nodoc:
    attr_reader :last_occurrence

    # Public: Writer for backfilling option.
    attr_writer :backfill

    # Public: Start time offset from epoch used for calculating run
    # times in the Sidetiq schedules.
    def self.start_time
      Sidetiq.config.utc ? Time.utc(2010, 1, 1) : Time.local(2010, 1, 1)
    end

    def initialize # :nodoc:
      @schedule = IceCube::Schedule.new(self.class.start_time)
    end

    def method_missing(meth, *args, &block) # :nodoc:
      if IceCube::Rule.respond_to?(meth)
        rule = IceCube::Rule.send(meth, *args, &block)
        @schedule.add_recurrence_rule(rule)
        rule
      elsif @schedule.respond_to?(meth)
        @schedule.send(meth, *args, &block)
      else
        super
      end
    end

    # Public: Checks if a job is disabled
    #
    # Returns true if a job is disabled, otherwise false.
    def disabled?(worker)
      Sidekiq.redis do |redis|
        return redis.get("sidetiq:#{Sidetiq.namespace(worker)}:disabled") == 'true' ? true : false
      end
    end

    # Public: Checks if a job is due to be scheduled.
    #
    # Returns true if a job is due, otherwise false.
    def schedule_next?(time)
      next_occurrence = @schedule.next_occurrence(time)
      if @last_scheduled != next_occurrence.to_i
        @last_scheduled = next_occurrence.to_i
        return true
      end
      false
    end

    # Public: Schedule to String.
    #
    # Examples
    #
    #   class MyWorker
    #     include Sidekiq::Worker
    #     include Sidetiq::Schedulable
    #
    #     recurrence { daily }
    #
    #     def perform
    #     end
    #   end
    #
    #   Sidetiq.schedules[MyWorker].to_s
    #   # => "Daily"
    #
    # Returns a String representing the schedule.
    def to_s
      @schedule.to_s
    end

    # Public: Inquirer for backfilling option.
    def backfill?
      !!@backfill
    end

    # Internal: Set schedule options.
    def set_options(hash)
      self.backfill = hash[:backfill] if !hash[:backfill].nil?
    end
  end
end

