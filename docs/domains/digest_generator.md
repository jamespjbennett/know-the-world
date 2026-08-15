# Digest Generator

> **Status:** Implemented (Tavily search + Anthropic Haiku defaults; jobs still planned).  
> **Code:** `app/services/digest_generator.rb`, `app/services/digest_generator/`, `app/services/search/`, `app/services/llm/`  
> **Technical tests:** `test/services/digest_generator_test.rb`, `test/services/search/`, `test/services/llm/`

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

Today the generator asks the LLM for `quiz_size` new questions. When review slots are filled, some of those new questions may not land on the quiz (they stay in the bank for later review). See `docs/TECH_DEBT.md`.

---

## Flow

1. Look up an existing digest for that `published_on`:
   - **ready** → raise `AlreadyGenerated` (already done for that day)
   - **failed / generating / pending** → wipe the stuck attempt and reuse the row (so job retries work)
   - **none** → create a new digest in **generating** status
2. Build search query from topic name + goal + knowledge level (`Search::QueryBuilder`)
3. Run web search via injected `search_client`
4. LLM synthesizes digest content + sources via injected `llm_client`
5. LLM generates `quiz_size` new MCQs from the digest content
6. In one database transaction: save content/sources, persist questions, create pending quiz, [Quiz Assembler](quiz_assembler.md) mixes ~70% new / ~30% review, mark digest **ready**, touch `last_activity_at`

Search and LLM calls stay **outside** the transaction so a slow API doesn't hold DB locks.

---

## What can go wrong?

| Situation | What happens |
|---|---|
| Ready digest already exists for that day | Raises `AlreadyGenerated` — won't overwrite a finished briefing |
| Search, LLM, or any other generation error | Digest marked **failed**, error re-raised — safe to retry later |
| Missing API keys | `ApiCredentials` raises `KeyError` before/during client use |

---

## LLM payload contract

Adapters may return **symbol or string keys**. The generator normalizes both.

**Synthesis** must include:

| Key | Type | Meaning |
|---|---|---|
| `content` | string | Digest body shown to the user |
| `sources` | array of hashes | Citations (e.g. `title`, `url`) — stored as JSON string keys |

**Each generated question** must include: `prompt`, `options`, `correct_index`, `explanation`.

Only those question fields are persisted (extra LLM keys are ignored).

---

## Example

You subscribe to Climate Tech (beginner, goal: “track policy”). Generator:

- Searches with a query including topic, goal, and level
- Writes a ready digest with cited sources
- Creates 10 new questions (first digest → quiz is all new material)
- Later digests pull ~3 review questions from your bank

If search is down, the digest ends **failed**. The next job run resets that row and tries again.

---

## Dependencies (injected)

| Client | Role | Status |
|---|---|---|
| `Search::TavilyClient` | Web search (Tavily) | **Default** when no client injected |
| `Llm::AnthropicClient` | Digest + MCQs (Claude Haiku) | **Default** when no client injected |
| Test fakes | Same interfaces | Used in service tests |

**API keys** (never commit plaintext keys):

```yaml
# bin/rails credentials:edit
anthropic:
  api_key: sk-ant-...
tavily:
  api_key: tvly-...
```

Or set `ANTHROPIC_API_KEY` / `TAVILY_API_KEY` (ENV wins over credentials). Read via `ApiCredentials`.

---

## What it doesn't do (v1)

- Enqueue itself (`GenerateDigestJob` / cron still planned)
- Score quizzes or update fitness (that's [Record Quiz Completion](record_quiz_completion.md))
- Switch LLM model without config change (default is Haiku; bump constant/credentials later if needed)

---

## Related docs

- [Architecture overview](../ARCHITECTURE.md) — pipeline status
- [Quiz Assembler](quiz_assembler.md) — new + review mix
- [Review Question Picker](review_question_picker.md) — which old questions return
- [Product overview (PRD)](../PRD.md) — content pipeline requirements
- [Tech debt](../TECH_DEBT.md) — surplus new questions when review fills slots
