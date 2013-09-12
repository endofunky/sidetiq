class OptionalArgumentWorker
	include Sidekiq::Worker
  include Sidetiq::Schedulable

  def perform(last_tick = nil)
  end
end

