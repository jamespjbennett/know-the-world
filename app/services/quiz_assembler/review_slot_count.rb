class QuizAssembler
  class ReviewSlotCount
    def self.for(quiz_size)
      (quiz_size * QuizAssembler::REVIEW_RATIO).round
    end
  end
end
