require 'sidetiq'
require 'sidekiq/web'

module Sidetiq
  module Web
    VIEWS = File.expand_path('views', File.dirname(__FILE__))

    def self.registered(app)
      app.get "/sidetiq" do
        @workers = Sidetiq.workers.sort_by { |worker| worker.name }
        @time = Sidetiq.clock.gettime
        erb File.read(File.join(VIEWS, 'sidetiq.erb')), locals: {view_path: VIEWS}
      end

      app.get "/sidetiq/locks" do
        begin
          @locks = Sidetiq::Lock::Redis.all.map(&:meta_data)
          @locks_available = true
        rescue Redis::CommandError
          @locks_available = false
        end

        erb File.read(File.join(VIEWS, 'locks.erb')), locals: {view_path: VIEWS}
      end

      app.get "/sidetiq/:name/schedule" do
        halt 404 unless (name = params[:name])

        @time = Sidetiq.clock.gettime

        @worker = Sidetiq.workers.detect do |worker|
          worker.name == name
        end

        @schedule = @worker.schedule

        erb File.read(File.join(VIEWS, 'schedule.erb')), locals: {view_path: VIEWS}
      end

      app.get "/sidetiq/:name/history" do
        halt 404 unless (name = params[:name])

        @time = Sidetiq.clock.gettime

        @worker = Sidetiq.workers.detect do |worker|
          worker.name == name
        end

        @history = Sidekiq.redis do |redis|
          redis.lrange("sidetiq:#{name}:history", 0, -1)
        end

        erb File.read(File.join(VIEWS, 'history.erb')), locals: {view_path: VIEWS}
      end

      app.post "/sidetiq/:name/trigger" do
        halt 404 unless (name = params[:name])

        worker = Sidetiq.workers.detect do |worker|
          worker.name == name
        end

        case worker.instance_method(:perform).arity.abs
        when 0
          worker.perform_async
        when 1
          Sidekiq.redis do |redis|
            last_run = (redis.get("sidetiq:#{worker.name}:last") || -1).to_f
            worker.perform_async(last_run)
          end
        else
          Sidekiq.redis do |redis|
            last_run = (redis.get("sidetiq:#{worker.name}:last") || -1).to_f
            worker.perform_async(last_run, Sidetiq.clock.gettime.to_i)
          end
        end

        redirect "#{root_path}sidetiq"
      end

      app.post "/sidetiq/:name/unlock" do
        halt 404 unless (name = params[:name])

        Sidetiq::Lock::Redis.new(name).unlock!

        redirect "#{root_path}sidetiq/locks"
      end

      app.post '/sidetiq/:name/deactivate' do
        halt 404 unless (name = params[:name])

        worker = Sidetiq.workers.find { |w| w.name == name }
        halt 404 if worker.nil?

        Sidekiq.redis do |redis|
          redis.set "sidetiq:#{worker.name}:active", '0'
        end

        redirect "#{root_path}sidetiq"
      end

      app.post '/sidetiq/:name/activate' do
        halt 404 unless (name = params[:name])

        worker = Sidetiq.workers.find { |w| w.name == name }
        halt 404 if worker.nil?

        Sidekiq.redis do |redis|
          redis.set "sidetiq:#{worker.name}:active", '1'
        end

        redirect "#{root_path}sidetiq"
      end
    end
  end
end

Sidekiq::Web.register(Sidetiq::Web)
Sidekiq::Web.tabs["Sidetiq"] = "sidetiq"
