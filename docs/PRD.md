# Know The World — Product Requirements Document

> Source of truth for product and architecture decisions. For the high-level system map see [ARCHITECTURE.md](ARCHITECTURE.md). For a concise agent summary, see `.cursor/rules/project-context.mdc`.

## Vision

**Know The World** helps users build lasting knowledge in topics they care about — climate tech, cricket history, UK politics, anything — through AI-generated briefings and quizzes that compound over time. News and web content feed fresh material into chosen topics; the app is not a daily headlines quiz, but a **topic fitness tracker** for understanding.

**Core loop:** Follow topics → Read digest → Take quiz → Fitness score goes up → Repeat.

---

## Decisions Summary

| Decision | Choice |
|---|---|
| Primary identity | Topic fitness; news as input source |
| Topic selection | Hybrid: curated starters + custom LLM topics |
| Daily experience | Digest (~3–5 min read) then quiz (5–10 MCQs) |
| Cadence | User picks daily or weekly per topic |
| Fitness model | 0–100 Topic Fitness Score + streak + trend chart |
| Onboarding depth | Topic + cadence + knowledge level + free-text goal |
| Content pipeline | Web search API → LLM synthesis → digest + questions |
| Review mix | ~30% of each quiz revisits prior material via `ReviewQuestionPicker` |
| Auth | Rails 8 built-in authentication (email/password) |
| API | Parallel `/api/v1/` namespace, shared service layer |
| Question format | MCQ only (4 options + explanation) |
| Topic limit | 3 topics max per user in v1 |
| Notifications | In-app only (no email/push in v1) |
| First digest | Instant on onboarding (async job), cron for subsequent |

---

## Target User

Primary: **Curious self-learners** who read news but feel they're missing context. They enjoy quizzes and want structured, low-effort ways to go deeper on subjects they pick — not a formal course, not passive scrolling.

Initial user: building this as a modern Rails practice app while dogfooding the core loop.

---

## User Flows

### Onboarding

1. Sign up (email + password via Rails 8 auth generator)
2. Pick a topic from curated list **or** describe a custom topic
3. Set cadence (daily / weekly), knowledge level (beginner / intermediate / advanced), and a one-sentence goal
4. `GenerateDigestJob` runs immediately — dashboard shows progress
5. Digest + quiz appear when ready (~1–3 min)

### Daily visit

1. Open app → dashboard shows topics with today's/this week's status
2. Tap topic → read digest (with source links)
3. Start quiz → 5–10 MCQs (~70% from today's digest, ~30% review questions)
4. See results + explanations → fitness score updates, streak increments
5. Trend chart shows score history per topic

### Add topic (up to 3)

Same as onboarding steps 2–5 for an additional topic. Block at 3 with clear messaging.

---

## v1 Feature Scope

### In scope

- **Auth**: Sign up, sign in, sign out (Rails 8 authentication generator)
- **Curated topics**: Seed ~15 topics in `db/seeds.rb`
- **Custom topics**: Free-text name + LLM-generated topic profile stored on subscription
- **Topic subscriptions**: `cadence`, `knowledge_level`, `goal`, `fitness_score`, `streak_count`
- **Digest generation**: Web search → LLM briefing with source URLs
- **Quiz generation**: MCQ bank tagged by topic, date, and user performance
- **Review questions**: ~30% of each quiz selected by `ReviewQuestionPicker` from prior question bank
- **Fitness scoring**: Composite score (accuracy + consistency + retention weights)
- **Dashboard**: Topic cards showing digest status, score, streak
- **Cron scheduling**: Daily Solid Queue recurring job; generates only for topics due that day
- **JSON API**: `/api/v1/` mirroring core resources
- **Instant first digest**: Same job pipeline triggered on subscription create

### Deferred (v2+)

- Email / push notifications
- Badges, leaderboards, social features
- Free-text quiz questions with LLM grading
- Deep LLM onboarding interview
- Lesson paths / multi-day curriculum
- RSS feed curation for curated topics
- Monetization / paid tiers
- Mobile app (API ready, client not)
- Web push via PWA

---

## Domain Model

**Key models:**

- `Topic` — curated (seeded) or custom (LLM profile in `profile` JSON column)
- `TopicSubscription` — join between User and Topic with personalization fields
- `Digest` — one per subscription per period (day or week)
- `Quiz` — belongs to Digest; assembled from new + review questions
- `Question` — MCQ bank per subscription; review flag lives on `quiz_questions`
- `QuestionAttempt` — per-user answer tracking for scoring and repetition scheduling
- `FitnessSnapshot` — daily score snapshot for trend charts

---

## Content Pipeline

**Job: `GenerateDigestJob`** (also triggered on subscription create)

1. Build search query from topic name + user goal + knowledge level
2. Call web search API (Brave Search or Tavily)
3. LLM: synthesize digest from results, cite sources, calibrate to knowledge level
4. LLM: generate 7–10 new MCQs from digest content
5. `ReviewQuestionPicker` selects review questions from the user's question bank
6. `QuizAssembler` combines new and review questions; save digest, quiz, questions; update subscription `last_activity_at`

**Job: `DailyGenerationJob`** (Solid Queue recurring, runs daily ~5am)

- Query subscriptions where cadence = daily OR (cadence = weekly AND today = subscription's weekly day)
- Enqueue `GenerateDigestJob` for each

**Services (shared by web + API):**

- `DigestGenerator` — orchestrates search + LLM + save
- `ReviewQuestionPicker` — picks review questions from bank
- `QuizAssembler` — mixes new + review questions
- `FitnessScorer` — recalculates score after quiz completion

---

## Fitness Score Formula (v1)

- **Accuracy** (50%): rolling average of last 10 quiz scores
- **Consistency** (30%): streak length vs. expected cadence
- **Retention** (20%): accuracy on review questions

Score range: 0–100. Snapshot stored daily for trend chart.

---

## Rails 8 Architecture

| Layer | Technology |
|---|---|
| Framework | Rails 8.1, PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus), Propshaft |
| Jobs | Solid Queue (`config/recurring.yml`) |
| Cache | Solid Cache |
| Deploy | Kamal + Docker |
| Auth | `bin/rails generate authentication` |
| API | `/api/v1/` namespace, Jbuilder JSON views |
| LLM | Abstract behind `Llm::Client` |
| Search | Brave Search API or Tavily |

**Controller structure:**

```
app/controllers/
  dashboard_controller.rb
  topics_controller.rb
  digests_controller.rb
  quizzes_controller.rb
  topic_subscriptions_controller.rb
  api/v1/...
app/services/
  digest_generator.rb
  review_question_picker.rb
  quiz_assembler.rb
  fitness_scorer.rb
  llm/client.rb
  search/client.rb
app/jobs/
  generate_digest_job.rb
  daily_generation_job.rb
  fitness_snapshot_job.rb
```

**API endpoints (v1):**

- `POST /api/v1/sessions`
- `GET /api/v1/topic_subscriptions`
- `POST /api/v1/topic_subscriptions`
- `GET /api/v1/digests/:id`
- `GET /api/v1/quizzes/:id`
- `POST /api/v1/quizzes/:id/submit`

---

## Curated Starter Topics

Climate Tech, Artificial Intelligence, UK Politics, US Politics, Environment & Sustainability, Global Economics, Middle East, Space Exploration, Cricket, Football (World), Science Breakthroughs, Public Health, Renewable Energy, Cybersecurity, History (20th Century)

---

## Implementation Phases

1. **Foundation** — Auth, models, migrations, seeds, dashboard skeleton
2. **Content pipeline** — Search + LLM services, `GenerateDigestJob`, instant first digest
3. **Quiz + fitness** — Quiz UI, review question picking, fitness scoring, trend chart
4. **Cron + polish** — `DailyGenerationJob`, onboarding wizard, topic limit enforcement
5. **API layer** — `/api/v1/` controllers, token auth, request specs

---

## Open Questions

- **LLM provider**: Anthropic (Haiku default) — decided
- **Search provider**: Tavily — decided
- **Weekly cadence day**: Default to subscription creation day-of-week
- **Digest length**: Target ~500–800 words
