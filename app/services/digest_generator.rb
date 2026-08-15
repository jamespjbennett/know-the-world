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
    ensure_not_generated!
    create_digest!
    generate_or_fail
  end

  private

  def ensure_not_generated!
    fail AlreadyGenerated if existing_digest?
  end

  def existing_digest?
    subscription.digests.exists?(published_on: @request.published_on)
  end

  def create_digest!
    @digest = subscription.digests.create!(
      published_on: @request.published_on,
      status: :generating
    )
  end

  def generate_or_fail
    generate
  rescue Search::Client::Error, Llm::Client::Error
    mark_failed!
    raise
  end

  def generate
    apply_synthesis!(synthesize)
    questions = persist_questions
    quiz = assemble_quiz(questions)
    finalize!(quiz, questions)
  end

  def synthesize
    llm.synthesize(
      subscription: subscription,
      search_results: search_results
    )
  end

  def search_results
    @request.search_client.search(search_query)
  end

  def search_query
    Search::QueryBuilder.for(subscription)
  end

  def apply_synthesis!(synthesis)
    @digest.update!(
      content: synthesis.fetch(:content),
      sources: stringify_sources(synthesis.fetch(:sources))
    )
  end

  def stringify_sources(sources)
    sources.map { |source| source.deep_stringify_keys }
  end

  def persist_questions
    QuestionPersister.new(subscription, @digest).persist(question_payloads)
  end

  def question_payloads
    llm.generate_questions(
      subscription: subscription,
      digest_content: @digest.content,
      count: @request.quiz_size
    )
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
    @digest.update!(status: :failed)
  end

  def subscription
    @request.subscription
  end

  def llm
    @request.llm_client
  end
end
