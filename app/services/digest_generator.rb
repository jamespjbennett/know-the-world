class DigestGenerator
  DEFAULT_QUIZ_SIZE = 10

  Result = Data.define(:digest, :quiz, :new_questions)
  Request = Data.define(
    :subscription,
    :published_on,
    :quiz_size,
    :search_client,
    :llm_client
  )

  class Error < StandardError; end
  class AlreadyGenerated < Error; end

  def self.call(**options)
    new(RequestBuilder.build(**options)).call
  end

  def initialize(request)
    @request = request
  end

  def call
    prepare_digest!
    generate_or_fail
  end

  private

  def prepare_digest!
    existing = existing_digest
    fail AlreadyGenerated if existing&.ready?

    existing ? reset_digest!(existing) : create_digest!
  end

  def existing_digest
    subscription.digests.find_by(published_on: @request.published_on)
  end

  # Wipe a failed or stuck attempt so a job retry can start clean on the same day.
  def reset_digest!(digest)
    @digest = digest
    @digest.quiz&.destroy!
    @digest.questions.destroy_all
    @digest.update!(status: :generating, content: nil, sources: [])
  end

  def create_digest!
    @digest = subscription.digests.create!(
      published_on: @request.published_on,
      status: :generating
    )
  end

  def generate_or_fail
    generate
  rescue StandardError
    mark_failed!
    raise
  end

  def generate
    synthesis = normalize_hash(synthesize)
    payloads = question_payloads_for(synthesis[:content])
    persist_pipeline!(synthesis, payloads)
  end

  def synthesize
    llm.synthesize(subscription: subscription, search_results: search_results)
  end

  def search_results
    @request.search_client.search(search_query)
  end

  def search_query
    Search::QueryBuilder.for(subscription)
  end

  def question_payloads_for(digest_content)
    llm.generate_questions(
      subscription: subscription,
      digest_content: digest_content,
      count: @request.quiz_size
    )
  end

  # Keep search/LLM outside the DB transaction; commit digest + quiz together.
  def persist_pipeline!(synthesis, payloads)
    TopicDigest.transaction do
      apply_synthesis!(synthesis)
      finalize_with_questions!(payloads)
    end
  end

  def finalize_with_questions!(payloads)
    questions = QuestionPersister.new(subscription, @digest).persist(payloads)
    quiz = assemble_quiz(questions)
    finalize!(quiz, questions)
  end

  def apply_synthesis!(synthesis)
    @digest.update!(
      content: synthesis.fetch(:content),
      sources: stringify_sources(synthesis.fetch(:sources))
    )
  end

  def stringify_sources(sources)
    sources.map { |source| normalize_hash(source).deep_stringify_keys }
  end

  def normalize_hash(value)
    value.to_h.with_indifferent_access
  end

  def assemble_quiz(questions)
    QuizAssembler.call(
      quiz: create_pending_quiz!,
      new_questions: questions,
      quiz_size: @request.quiz_size
    )
  end

  def create_pending_quiz!
    @digest.create_quiz!(status: :pending)
  end

  def finalize!(quiz, questions)
    @digest.update!(status: :ready)
    touch_activity!
    Result.new(digest: @digest, quiz: quiz, new_questions: questions)
  end

  def touch_activity!
    subscription.update!(last_activity_at: Time.current)
  end

  def mark_failed!
    @digest&.update!(status: :failed)
  end

  def subscription
    @request.subscription
  end

  def llm
    @request.llm_client
  end
end
