module Sidetiq
  module Actor
    class CelluloidWrapper
      attr_reader :job

      def initialize(actor)
        @actor = actor
      end

      def terminate(wait=false)
        @actor.terminate
      rescue ::Celluloid::DeadActorError => e
        Sidetiq.logger.debug e.message
      end

      def kill(wait=false)
        @actor.kill
      rescue ::Celluloid::DeadActorError => e
        Sidetiq.logger.debug e.message
      end

      def start
        @actor.start
      rescue ::Celluloid::DeadActorError => e
        Sidetiq.logger.debug e.message
      end
    end

    def self.included(base)
      base.__send__(:include, Celluloid)
      base.finalizer :sidetiq_finalizer
    end

    def initialize(*args, &block)
      log_call "initialize"

      super

      # Link to Sidekiq::Manager when running in server-mode. In most
      # cases the supervisor is booted before Sidekiq has launched
      # fully, so defer this.
      if Sidekiq.server?
        after(0.1) { link_to_sidekiq_manager }
      end
    end

    private

    def sidetiq_finalizer
      log_call "shutting down ..."
    end

    def link_to_sidekiq_manager
      if Sidekiq::CLI.instance.launcher.present? && Sidekiq::CLI.instance.launcher.manager.present?
        begin
          p = ::Sidetiq::Actor::CelluloidWrapper.new(current_actor)
          Sidekiq::CLI.instance.launcher.manager.workers << p
          current_actor
        rescue RuntimeError => e
          debug "Can't link #{self.class.name}. Sidekiq::Manager is in iteration. Retrying in 5 seconds ..."
          after(5) { link_to_sidekiq_manager }
        end
      else
        debug "Can't link #{self.class.name}. Sidekiq::Manager not running. Retrying in 5 seconds ..."
        after(5) { link_to_sidekiq_manager }
      end
    end

    def log_call(call)
      info "#{self.class.name} id: #{object_id} #{call}"
    end
  end
end
