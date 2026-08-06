# Quiz Assembler

> **Status:** Implemented.  
> **Code:** `app/services/quiz_assembler/`  
> **Technical tests:** `test/services/quiz_assembler_test.rb`

---

## What is it?

A quiz isn't only today's new questions. **Quiz Assembler** puts the full quiz together: mostly questions from today's briefing, plus a handful of old ones to revisit.

It answers: *"Here's today's complete quiz — new material first, then review."*

---

## When does it run?

During digest generation, after:

1. Today's briefing has been written
2. New MCQs have been generated from that briefing
3. Old questions are available to pick from (if any)

It runs **before** the quiz is shown to the user.

---

## What does it produce?

A quiz with **5–10 questions** (or fewer if not enough exist yet), roughly:

| Part | Share | Source |
|---|---|---|
| **New material** | ~70% | Questions from today's digest |
| **Review** | ~30% | Questions chosen by [Review Question Picker](review_question_picker.md) |

New questions come **first** (positions 1, 2, 3…), then review questions.

Each question is saved on the quiz with a `review` flag so the app knows which is which.

---

## Example

Today's quiz target size: **10 questions**

- 7 new questions from the climate tech briefing
- 3 review questions from past quizzes (prioritizing ones you got wrong)

Quiz Assembler creates all 10 `QuizQuestion` rows in order and returns the ready quiz.

On your **first quiz**, there's no history yet — all 10 slots are new material.

---

## How does this impact the app?

| Component | Role |
|---|---|
| [Review Question Picker](review_question_picker.md) | Chooses which old questions to include |
| **Quiz Assembler** | Combines new + review into one ordered quiz |
| [Fitness Scorer](fitness_scorer.md) | Scores you after you complete the assembled quiz |

Without Quiz Assembler, something else would have to figure out the 70/30 mix and question order — this service owns that logic.

---

## What it doesn't do (v1)

- It doesn't generate new questions (that's the digest/LLM pipeline)
- It doesn't pick which review questions (delegates to Review Question Picker)
- It doesn't score the quiz (that's Fitness Scorer after completion)

---

## Related docs

- [Architecture overview](../ARCHITECTURE.md) — where this fits in the pipeline
- [Product overview (PRD)](../PRD.md) — full app spec
