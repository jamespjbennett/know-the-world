# Tech Debt & Scaling Issues

Known issues we're deferring intentionally. Add new items here when you spot performance, scaling, or maintainability concerns during development — don't rely on memory or chat history.

**When to add an entry:** N+1 queries, missing indexes, unbounded loads, security gaps, missing error handling at scale, or "fine for v1 but won't scale" decisions.

**Entry format:** Use the template below. Keep descriptions short and actionable.

---

## Open

### ReviewQuestionPicker — N+1 on question attempts

| | |
|---|---|
| **Area** | `app/services/review_question_picker/` |
| **Severity** | Medium |
| **Added** | 2026-08-05 |

**Problem:** `QuestionPriority#latest_attempt_for` runs one DB query per question when sorting candidates. With 40 questions in the bank, that's ~41 queries per pick (1 for questions + 40 for attempts).

**Impact now:** Low — v1 caps users at 3 topics with ~7–10 questions per quiz; banks stay small during dogfooding.

**Fix when ready:** Batch-load latest attempts in one query (e.g. Postgres `DISTINCT ON (question_id)`), index by `question_id`, rank in memory. Optionally push sort + `LIMIT` into SQL so we don't load the entire bank when `count` is small.

**Related tests:** `test/services/review_question_picker_test.rb` — must stay green after refactor.

---

### QuizAssembler — surplus new questions left off quiz

| | |
|---|---|
| **Area** | `app/services/quiz_assembler.rb`, `app/services/digest_generator.rb` |
| **Severity** | Low |
| **Added** | 2026-08-06 |
| **Updated** | 2026-08-15 |

**Problem:** `DigestGenerator` always requests `quiz_size` new questions from the LLM. When review slots are filled, `QuizAssembler#selected_new_questions` only takes the first N (`quiz_size - review_count`). Leftover new questions remain in the DB (linked to today's digest) but are not attached to the quiz via `QuizQuestion`. Behaviour is implicit: they sit in the question bank and may appear as review questions later. This is undocumented product behaviour in the UI sense — noted in [digest_generator.md](domains/digest_generator.md) — not a bug, but an unresolved design choice.

**Example:** `quiz_size: 10`, 3 review slots filled from old bank → 7 new used, 3 newly generated questions discarded from today's quiz.

**Impact now:** Low — surplus questions aren't lost from the DB and can resurface in review. May confuse users if we ever expose "all questions from this digest" or if LLM generation cost matters.

**Fix when ready:** Decide explicitly and implement one of:
1. **Generate exactly what's needed** — `DigestGenerator` produces `new_count` only (simplest)
2. **Keep surplus deliberately** — optionally mark questions as `unused` vs `asked`
3. **Delete surplus** — remove questions not placed on the quiz (keeps bank clean; loses review fodder)

**Related tests:** `test/services/quiz_assembler_test.rb`, `test/services/digest_generator_test.rb`

---

## Template (copy for new entries)

```markdown
### [Component] — [Short title]

| | |
|---|---|
| **Area** | `path/to/code` |
| **Severity** | Low / Medium / High |
| **Added** | YYYY-MM-DD |

**Problem:** What is wrong or inefficient?

**Impact now:** Why it's acceptable to defer (or why it isn't).

**Fix when ready:** Concrete steps to resolve.

**Related tests:** Specs to run after fix.
```

---

## Resolved

_Move items here when fixed, with date and brief note._
