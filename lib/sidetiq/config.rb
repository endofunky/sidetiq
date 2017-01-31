module Sidetiq
  class << self
    # Public: Sets the configuration used by Sidetiq.
    attr_writer :config

    # Public: Configuration wrapper for block configurations.
    #
    # Examples
    #
    #   Sidetiq.configure do |config|
    #     config.resolution = 0.2
    #   end
    #
    # Yields the configuration OpenStruct currently set.
    # Returns nothing.
    def configure
      yield config
    end

    # Public: Returns the current configuration used by Sidetiq.
    def config
      @config ||= Sidetiq::Config.new
    end
  end

  class Config < OpenStruct
    def enqueue_jobs?
      if enqueue_jobs.respond_to? :call
        enqueue_jobs.call
      else
        enqueue_jobs
      end
    end
  end

  configure do |config|
    config.worker_history = 50
    config.resolution = 1
    config.lock_expire = 1000
    config.utc = false
    config.handler_pool_size = nil
    config.enqueue_jobs = true
  end
end

