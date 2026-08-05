# Review Question Picker

> **Status:** Implemented.  
> **Code:** `app/services/review_question_picker/`  
> **Technical tests:** `test/services/review_question_picker_test.rb`

---

## What is it?

When you take a quiz, not every question is about today's briefing. About **30% are review questions** — things you've been tested on before, mixed in to see if you still remember them.

**Review Question Picker** chooses which old questions to pull back in for the next quiz.

---

## When does it run?

When a new quiz is being assembled for a topic you follow — after today's new questions have been generated from the briefing, but before the quiz is saved.

It answers: *"Which 2–3 old questions should we ask again?"*

---

## What does it pick from?

Your **question bank** for that topic — every question you've been tested on in **past completed quizzes** for that subscription.

It does **not** pick from:

- Today's brand-new questions (those are passed in an exclude list)
- Quizzes you started but didn't finish
- Another topic's questions

---

## How does it choose?

Priority order:

1. **Questions you got wrong before** — these come back first
2. **Questions you got right** — if more review slots are needed
3. **Never duplicates** — the same question won't appear twice in one pick

If you're on your **first quiz** for a topic, there's nothing to review yet — it returns an empty list.

If you request 3 review questions but only 2 exist in your history, you get 2.

---

## Example

You've done two quizzes on Climate Tech.

**Quiz 1 (last week):**
- "What is direct air capture?" — you got it **wrong**
- "Which country leads in solar?" — you got it **right**

**Quiz 2 (yesterday):**
- "What is a carbon credit?" — you got it **right**

Today's new quiz needs **3 review questions** but only **3 old ones exist**. Review Question Picker returns all three, with the direct air capture question first because you missed it.

---

## How does this impact the app?

| Without it | With it |
|---|---|
| Every quiz is only about today's news | Quizzes reinforce what you've learned before |
| Easy to forget last week's material | Wrong answers come back until you know them |
| Retention score in fitness scoring means nothing | Retention score reflects real review performance |

Review Question Picker feeds into **Quiz Assembler**, which combines today's new questions with the picked review questions into one quiz (~70% new, ~30% review).

---

## What it doesn't do (v1)

- It doesn't generate new questions — that's the digest/LLM pipeline
- It doesn't decide how many review questions (Quiz Assembler passes in a count, usually ~30% of quiz size)
- It doesn't score the quiz — that's Fitness Scorer after you finish

---

## Related docs

- [Fitness Scorer](fitness_scorer.md) — retention score uses review question results
- [Product overview (PRD)](../PRD.md) — full app spec
