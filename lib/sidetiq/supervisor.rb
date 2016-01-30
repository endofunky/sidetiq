module Sidetiq
  class Supervisor < Celluloid::Supervision::Container
    supervise as: :sidetiq_clock, type: Sidetiq::Actor::Clock

    if Sidekiq.server?
      if handler_pool_size = Sidetiq.config.handler_pool_size
        pool Sidetiq::Actor::Handler,
             as: :sidetiq_handler,
             size: handler_pool_size
      else
        # Use Celluloid's CPU-based default.
        pool Sidetiq::Actor::Handler,
             as: :sidetiq_handler
      end
    end

    class << self
      include Logging

      def clock
        run! if Celluloid::Actor[:sidetiq_clock].nil?
        Celluloid::Actor[:sidetiq_clock]
      end

      def handler
        run! if Celluloid::Actor[:sidetiq_handler].nil?
        Celluloid::Actor[:sidetiq_handler]
      end

      def run!
        motd
        info "Sidetiq::Supervisor start"
        super
      end

      def run
        raise "Sidetiq::Supervisor should not be run in foreground."
      end

      private

      def motd
        info "Sidetiq v#{VERSION::STRING} - Copyright (c) 2012-2013, Tobias Svensson <tob@tobiassvensson.co.uk>"
        info "Sidetiq is covered by the 3-clause BSD license."
        info "See LICENSE and http://opensource.org/licenses/BSD-3-Clause for licensing details."
      end
    end
  end
end

