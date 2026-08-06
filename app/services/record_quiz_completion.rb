class RecordQuizCompletion
  Result = Data.define(:quiz, :subscription, :fitness)

  class Error < StandardError; end
  class AlreadyCompleted < Error; end
  class IncompleteAttempts < Error; end
  class Forbidden < Error; end
  class NotInProgress < Error; end

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
    ensure_owner!
    ensure_ready_to_complete!
    AttemptValidator.new(@quiz, @user).validate!
  end

  # Only the person who follows this topic can submit their own quiz.
  def ensure_owner!
    raise Forbidden unless @user.id == @subscription.user_id
  end

  # Submits only work once the quiz has been started — not before, and not again after.
  def ensure_ready_to_complete!
    raise AlreadyCompleted if @quiz.completed?
    raise NotInProgress unless @quiz.in_progress?
  end

  def complete_in_transaction
    TopicSubscription.transaction do
      claim_quiz_for_completion!
      apply_completion!
      build_result
    end
  end

  # Lock the rows so two "Submit" taps can't both finish the same quiz and bump the streak twice.
  def claim_quiz_for_completion!
    @subscription.lock!
    @quiz.lock!
    raise AlreadyCompleted if @quiz.completed?
  end

  def apply_completion!
    finalize_quiz
    increment_streak
    @fitness = recalculate_fitness
    persist_fitness
    record_snapshot
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
