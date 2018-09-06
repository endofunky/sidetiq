# stdlib
require 'ostruct'
require 'singleton'
require 'socket'
require 'time'

# gems
require 'ice_cube'
require 'sidekiq'
require 'celluloid/pool'

# internal
require 'sidetiq/config'
require 'sidetiq/logging'
require 'sidetiq/api'
require 'sidetiq/subclass_tracking'
require 'sidetiq/clock'
require 'sidetiq/handler'
require 'sidetiq/lock/meta_data'
require 'sidetiq/lock/redis'
require 'sidetiq/schedule'
require 'sidetiq/schedulable'
require 'sidetiq/version'

# middleware
require 'sidetiq/middleware/history'

# actor topology
require 'sidetiq/actor'
require 'sidetiq/actor/clock'
require 'sidetiq/actor/handler'
require 'sidetiq/supervisor'

# The Sidetiq namespace.
module Sidetiq
  include Sidetiq::API

  # Expose all instance methods as singleton methods.
  extend self

  class << self
    # Public: Setter for the Sidetiq logger.
    attr_writer :logger
  end

  # Public: Reader for the Sidetiq logger.
  #
  # Defaults to `Sidekiq.logger`.
  def logger
    @logger ||= Sidekiq.logger
  end

  # Public: Returns the Sidetiq::Clock actor.
  def clock
    Sidetiq::Supervisor.clock
  end

  # Public: Returns a Sidetiq::Handler worker.
  def handler
    Sidetiq::Supervisor.handler
  end
end

if Sidekiq.server?
  Sidetiq::Supervisor.run!
end
