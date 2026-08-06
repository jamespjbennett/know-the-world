# Record Quiz Completion

> **Status:** Implemented.  
> **Code:** `app/services/record_quiz_completion.rb`, `app/services/record_quiz_completion/`  
> **Technical tests:** `test/services/record_quiz_completion_test.rb`

---

## What is it?

When you finish a quiz, **Record Quiz Completion** wraps up everything that should happen in one go: score the quiz, update your fitness, bump your streak, and save a snapshot for the trend chart.

It answers: *"The user submitted their answers — now what?"*

---

## When does it run?

Once the user has answered **every question** on an in-progress quiz. Typically triggered when they tap "Submit" at the end.

It does **not** run while they're mid-quiz or if they've already completed that quiz.

---

## What does it do?

In order:

1. **Score the quiz** — percentage correct (e.g. 7/10 → 70)
2. **Mark quiz completed** — status, score, and timestamp saved
3. **Increment streak** — +1 on your topic subscription
4. **Recalculate fitness** — calls [Fitness Scorer](fitness_scorer.md) with the new streak
5. **Save fitness score** — updates your subscription's 0–100 score
6. **Record snapshot** — creates or updates today's entry on the trend chart
7. **Update last activity** — timestamp for when you last engaged with the topic

---

## Example

You finish a 4-question quiz on Climate Tech, getting 2 right.

- Quiz marked **50%** and completed
- Streak goes from **2 → 3**
- Fitness score recalculated (accuracy, consistency with new streak, retention on review questions)
- Today's snapshot updated so the chart reflects the new score

---

## What can go wrong?

| Situation | What happens |
|---|---|
| Quiz already completed | Raises `AlreadyCompleted` — can't submit twice (also protected if two submits hit at once) |
| Quiz not started yet | Raises `NotInProgress` — must be in progress before submitting |
| Wrong person | Raises `Forbidden` — only the topic follower can complete their quiz |
| Unanswered questions | Raises `IncompleteAttempts` — must answer all before submitting |

---

## How does this impact the app?

| Before | After |
|---|---|
| Quiz attempts exist but nothing persists | Quiz is done, fitness and streak reflect it |
| Fitness Scorer runs in isolation | Score actually saved to your profile |
| No trend data | Daily snapshot ready for the chart |

This is the bridge between **taking a quiz** and **seeing progress** on your dashboard.

---

## What it doesn't do (v1)

- It doesn't record individual answers — attempts must already exist
- It doesn't reset streaks for missed days — that's a separate concern
- It doesn't send notifications

---

## Related docs

- [Fitness Scorer](fitness_scorer.md) — how the score is calculated
- [Architecture overview](../ARCHITECTURE.md) — where this fits after quiz completion
