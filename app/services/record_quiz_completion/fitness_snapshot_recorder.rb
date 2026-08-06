class RecordQuizCompletion
  class FitnessSnapshotRecorder
    def self.record(subscription, score)
      snapshot = subscription.fitness_snapshots.find_or_initialize_by(recorded_on: Date.current)
      snapshot.update!(score: score)
    end
  end
end
