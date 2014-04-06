module Sidetiq
  module Lock
    class MetaData
      OWNER = "#{Socket.gethostname}:#{Process.pid}"

      attr_accessor :owner, :timestamp, :key

      class << self
        include Sidekiq::ExceptionHandler

        def for_new_lock(key)
          new(owner: OWNER, timestamp: Sidetiq.clock.gettime.to_f, key: key)
        end

        def from_json(json = '')
          # Avoid TypeError when nil is passed to Sidekiq.load_json.
          json ||= ''

          hash = Sidekiq.load_json(json).symbolize_keys
          new(hash)
        rescue StandardError => e
          if json != ''
            # Looks like garbage lock metadata, so report it.
            handle_exception(e, context: "Garbage lock meta data detected: #{json}")
          end

          new
        end
      end

      def initialize(hash = {})
        @owner = hash[:owner]
        @timestamp = hash[:timestamp]
        @key = hash[:key]
      end

      def pttl
        Sidekiq.redis { |r| r.pttl(key) }
      end

      def to_json
        instance_variables.each_with_object({}) do |var, hash|
          hash[var.to_s.delete("@")] = instance_variable_get(var)
        end.to_json
      end

      def to_s
        "Sidetiq::Lock on #{key} set at #{timestamp} by #{owner}"
      end
    end
  end
end

