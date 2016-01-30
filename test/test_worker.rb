require_relative 'helper'

class TestWorker < Sidetiq::TestCase
  class FakeWorker
    include Sidetiq::Schedulable
  end

  def test_timestamps_for_new_worker
    assert FakeWorker.last_scheduled_occurrence == -1
    assert FakeWorker.next_scheduled_occurrence == -1
  end

  def test_options
    assert BackfillWorker.schedule.backfill?
  end
end
