module Sidetiq
  # Public: The Sidetiq clock.
  class Clock
    include Logging

    def self.start!
      warn "Sidetiq::Clock#start! is deprecated. Calling it is no longer required."
    end

    def start!
      warn "Sidetiq::Clock#start! is deprecated. Calling it is no longer required."
    end

    # Internal: Returns a hash of Sidetiq::Schedule instances.
    attr_reader :schedules

    def initialize # :nodoc:
      super
    end

    # Public: Get the schedule for `worker`.
    #
    # worker - A Sidekiq::Worker class
    #
    # Examples
    #
    #   schedule_for(MyWorker)
    #   # => Sidetiq::Schedule
    #
    # Returns a Sidetiq::Schedule instances.
    def schedule_for(worker)
      if worker.respond_to?(:schedule)
        worker.schedule
      end
    end

    # Public: Issue a single clock tick.
    #
    # Examples
    #
    #   tick
    #   # => Hash of Sidetiq::Schedule objects
    #
    # Returns a hash of Sidetiq::Schedule instances.
    def tick(tick = gettime)
      Sidetiq.workers.each do |worker|
        Sidetiq.handler.dispatch(worker, tick)
      end
    end

    # Public: Returns the current time used by the clock.
    #
    # Examples
    #
    #   gettime
    #   # => 2013-02-04 12:00:45 +0000
    #
    # Returns a Time instance.
    def gettime
      Sidetiq.config.utc ? Time.now.utc : (Time.respond_to?(:current) ? Time.current : Time.now)
    end
  end
end

