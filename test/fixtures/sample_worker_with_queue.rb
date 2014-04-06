class SimpleWorkerWithQueue
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  sidekiq_options queue: 'test1234'

  recurrence { daily }

  def perform
  end
end
