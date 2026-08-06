class RecordQuizCompletion
  Result = Data.define(:quiz, :subscription, :fitness)

  class Error < StandardError; end
  class AlreadyCompleted < Error; end
  class IncompleteAttempts < Error; end

  def self.call(quiz:, user:)
    new(quiz, user).call
  end

  def initialize(quiz, user)
    @quiz = quiz
    @user = user
    @subscription = quiz.topic_subscription
  end

  def call
    validate!
    complete_in_transaction
  end

  private

  def validate!
    raise AlreadyCompleted if @quiz.completed?

    AttemptValidator.new(@quiz, @user).validate!
  end

  def complete_in_transaction
    TopicSubscription.transaction do
      finalize_quiz
      increment_streak
      @fitness = recalculate_fitness
      persist_fitness
      record_snapshot
      build_result
    end
  end

  def finalize_quiz
    @quiz.update!(status: :completed, score: quiz_score, completed_at: Time.current)
  end

  def increment_streak
    @subscription.increment!(:streak_count)
  end

  def recalculate_fitness
    FitnessScorer.call(@subscription.reload)
  end

  def persist_fitness
    @subscription.update!(fitness_score: @fitness.score, last_activity_at: Time.current)
  end

  def record_snapshot
    FitnessSnapshotRecorder.record(@subscription, @fitness.score)
  end

  def quiz_score
    QuizScoreCalculator.for(@quiz, user: @user)
  end

  def build_result
    Result.new(quiz: @quiz, subscription: @subscription.reload, fitness: @fitness)
  end
end
