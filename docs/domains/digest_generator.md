# Digest Generator

> **Status:** Implemented (orchestration + query builder; real search/LLM HTTP adapters still planned).  
> **Code:** `app/services/digest_generator.rb`, `app/services/digest_generator/`, `app/services/search/query_builder.rb`  
> **Technical tests:** `test/services/digest_generator_test.rb`, `test/services/search/query_builder_test.rb`

---

## What is it?

**Digest Generator** builds one period's briefing and quiz for a topic subscription: search the web, synthesize a digest with an LLM, generate new MCQs, then assemble the quiz (including review questions when history exists).

It answers: *"Create today's digest and quiz for this subscription."*

---

## When does it run?

Whenever a digest is needed for a subscription + publish date — typically from a job on subscribe (first digest) or the daily cron. Controllers should not own this logic; they enqueue or call the service.

---

## What does it produce?

A `DigestGenerator::Result` with:

| Field | Meaning |
|---|---|
| `digest` | `TopicDigest` marked **ready**, with content + sources |
| `quiz` | Pending `Quiz` assembled via [Quiz Assembler](quiz_assembler.md) |
| `new_questions` | New `Question` rows linked to the subscription and digest |

Default quiz size is **10** (`DigestGenerator::DEFAULT_QUIZ_SIZE`).

---

## Flow

1. Refuse if a digest already exists for that `published_on` (`AlreadyGenerated`)
2. Create digest in **generating** status
3. Build search query from topic name + goal + knowledge level (`Search::QueryBuilder`)
4. Run web search via injected `search_client`
5. LLM synthesizes digest content + sources via injected `llm_client`
6. LLM generates `quiz_size` new MCQs from the digest content
7. Persist questions; create pending quiz; [Quiz Assembler](quiz_assembler.md) mixes ~70% new / ~30% review
8. Mark digest **ready** and touch subscription `last_activity_at`

On search or LLM failure: digest is marked **failed** and the error is re-raised.

---

## Example

You subscribe to Climate Tech (beginner, goal: “track policy”). Generator:

- Searches with a query including topic, goal, and level
- Writes a ready digest with cited sources
- Creates 10 new questions (first digest → quiz is all new material)
- Later digests pull ~3 review questions from your bank

---

## Dependencies (injected)

| Client | Role | Status |
|---|---|---|
| `Search::Client` | Web search | Interface stub — inject a real adapter (or test fake) |
| `Llm::Client` | Digest synthesis + MCQ generation | Interface stub — inject a real adapter (or test fake) |

Live API keys and HTTP implementations are a follow-up; this service is fully testable with fakes.

---

## What it doesn't do (v1)

- Call real search/LLM APIs (adapters not wired yet)
- Enqueue itself (`GenerateDigestJob` / cron still planned)
- Score quizzes or update fitness (that's [Record Quiz Completion](record_quiz_completion.md))

---

## Related docs

- [Architecture overview](../ARCHITECTURE.md) — pipeline status
- [Quiz Assembler](quiz_assembler.md) — new + review mix
- [Review Question Picker](review_question_picker.md) — which old questions return
- [Product overview (PRD)](../PRD.md) — content pipeline requirements
