module Sidetiq
  configure do |config|
    config.priority = Thread.main.priority
    config.resolution = 1
    config.lock_expire = 1000
    config.utc = false
    config.time_args = true
  end

  # Public: The Sidetiq clock.
  class Clock
    include Singleton
    include MonitorMixin

    # Internal: Returns a hash of Sidetiq::Schedule instances.
    attr_reader :schedules

    # Internal: Returns the clock thread.
    attr_reader :thread

    def self.method_missing(meth, *args, &block) # :nodoc:
      instance.__send__(meth, *args, &block)
    end

    def initialize # :nodoc:
      super
      @schedules = {}
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
      schedules[worker] ||= Sidetiq::Schedule.new
    end

    # Public: Issue a single clock tick.
    #
    # Examples
    #
    #   tick
    #   # => Hash of Sidetiq::Schedule objects
    #
    # Returns a hash of Sidetiq::Schedule instances.
    def tick
      tick = gettime
      synchronize do
        schedules.each do |worker, sched|
          synchronize_clockworks(worker) do |redis|
            if sched.backfill? && (last = worker.last_scheduled_occurrence) > 0
              last = Sidetiq.config.utc ? Time.at(last).utc : Time.at(last)
              sched.occurrences_between(last + 1, tick).each do |past_t|
                enqueue(worker, past_t, redis)
              end
            end
            enqueue(worker, sched.next_occurrence(tick), redis)
          end if sched.schedule_next?(tick)
        end
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
      Sidetiq.config.utc ? Time.now.utc : Time.now
    end

    # Public: Starts the clock unless it is already running.
    #
    # Examples
    #
    #   start!
    #   # => Thread
    #
    # Returns the Thread instance of the clock thread.
    def start!
      return if ticking?

      Sidetiq.logger.info "Sidetiq::Clock start"

      @thread = Thread.start { clock { tick } }
      @thread.abort_on_exception = true
      @thread.priority = Sidetiq.config.priority
      @thread
    end

    # Public: Stops the clock if it is running.
    #
    # Examples
    #
    #   stop!
    #   # => nil
    #
    # Returns nil.
    def stop!
      if ticking?
        @thread.kill
        Sidetiq.logger.info "Sidetiq::Clock stop"
      end
    end

    # Public: Returns the status of the clock.
    #
    # Examples
    #
    #   ticking?
    #   # => false
    #
    #   start!
    #   ticking?
    #   # => true
    #
    # Returns true or false.
    def ticking?
      @thread && @thread.alive?
    end

    private

    def enqueue(worker, time, redis)
      key      = "sidetiq:#{worker.name}"
      time_f   = time.to_f
      next_run = (redis.get("#{key}:next") || -1).to_f

      if next_run < time_f
        Sidetiq.logger.info "Sidetiq::Clock enqueue #{worker.name} (at: #{time_f}) (last: #{next_run})"

        redis.mset("#{key}:last", next_run, "#{key}:next", time_f)

        if Sidetiq.config.time_args
          arity = [worker.instance_method(:perform).arity - 1, -1].max
          args = [next_run, time_f][0..arity]
          worker.perform_at(time, *args)
        else
          worker.perform_at(time)
        end
      end
    end

    def synchronize_clockworks(klass)
      lock = "sidetiq:#{klass.name}:lock"

      Sidekiq.redis do |redis|
        if redis.setnx(lock, 1)
          Sidetiq.logger.debug "Sidetiq::Clock lock #{lock}"

          begin
            redis.pexpire(lock, Sidetiq.config.lock_expire)
            yield redis
          ensure
            redis.del(lock)
            Sidetiq.logger.debug "Sidetiq::Clock unlock #{lock}"
          end
        end
      end
    end

    def clock
      loop do
        sleep_time = time { yield }

        if sleep_time > 0
          Thread.pass
          sleep sleep_time
        end
      end
    end

    def time
      start = gettime
      yield
      Sidetiq.config.resolution - (gettime.to_f - start.to_f)
    end
  end
end

