module Sidetiq
  module Middleware
    class History
      def call(worker, msg, queue, &block)
        if worker.kind_of?(Sidetiq::Schedulable)
          call_with_sidetiq_history(worker, msg, queue, &block)
        else
          yield
        end
      end

      private

      def call_with_sidetiq_history(worker, msg, queue)
        entry = new_history_entry
        start_time = Time.now

        yield
      rescue StandardError => e
        entry[:status] = :failure
        entry[:exception] = e.class.to_s
        entry[:error] = e.message
        entry[:backtrace] = e.backtrace

        raise e
      ensure
        entry[:runtime] = (Time.now - start_time)
        save_entry_for_worker(entry, worker)
      end

      def new_history_entry
        {
          status: :success,
          error: "",
          exception: "",
          backtrace: "",
          node: "#{Socket.gethostname}:#{Process.pid}-#{Thread.current.object_id}",
          timestamp: Time.now.iso8601,
          runtime: ""
        }
      end

      def save_entry_for_worker(entry, worker)
        Sidekiq.redis do |redis|
          list_name = "sidetiq:#{worker.class.name}:history"

          redis.lpush(list_name, Sidekiq.dump_json(entry))
          redis.ltrim(list_name, 0, Sidetiq.config.worker_history - 1)
        end
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidetiq::Middleware::History
  end
end
