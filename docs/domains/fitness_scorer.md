# Fitness Scorer

> **Status:** Implemented.  
> **Code:** `app/services/fitness_scorer/`  
> **Technical tests:** `test/services/fitness_scorer_test.rb`

---

## What is it?

Every topic you follow in Know The World has a **fitness score** — a number from 0 to 100 that answers:

> *"How well do I actually understand this topic right now?"*

Think of it like a Strava fitness score, but for knowledge instead of running. It goes up when you're learning well and showing up regularly. It reflects real understanding, not just whether you opened the app.

**Fitness Scorer** is the piece of the app that calculates that number.

---

## When does it run?

After you finish a quiz on a topic, Fitness Scorer recalculates your score for that topic. It also gets saved as a daily snapshot so you can see your progress on a chart over time.

It does **not** run when you read a digest — only when you've been tested.

---

## What goes into the score?

Your fitness score blends three things. Each matters, but not equally:

| Part | Weight | Plain English |
|---|---|---|
| **Accuracy** | 50% | How well you're doing on quizzes lately |
| **Consistency** | 30% | How regularly you keep up with the topic |
| **Retention** | 20% | Whether you still remember older material |

Together they produce one number: your **fitness score**.

---

## 1. Accuracy — "Am I getting the questions right?"

This looks at your **recent quiz results** for the topic.

- Uses your last **10 completed quizzes** (older ones drop off)
- If you scored 80%, 60%, and 90% on your last three quizzes, it averages those — and keeps going back up to 10
- Quizzes you started but didn't finish don't count
- If you haven't completed any quizzes yet, accuracy is 0

**Example:** You've done 10 quizzes and averaged 70% across them. Your accuracy component is 70.

---

## 2. Consistency — "Am I showing up?"

This rewards **habit**, like a Duolingo streak — but scaled to how often you said you wanted to learn.

- If you chose **daily**, the app expects you to keep a streak going for up to **7 days** to max this out
- If you chose **weekly**, it expects up to **4 weeks** in a row

Your streak count (days or weeks in a row you've kept up) is compared to that target.

**Example (daily):** You've kept your streak going for 3 days out of a possible 7. Your consistency is roughly 43% of the way to full marks.

**Example (weekly):** You've kept going for 2 weeks out of 4. Your consistency is 50%.

Once you hit the target (7 days or 4 weeks), consistency maxes out — you can't go above 100 on this part.

---

## 3. Retention — "Do I still remember old stuff?"

Each quiz mixes **new questions** (from today's briefing) with **review questions** (from things you learned before). Retention only looks at the review questions.

This answers: *"When we test you on something you learned a week ago, do you still know it?"*

- If you get 2 out of 3 review questions right, retention is about 67%
- If a quiz has no review questions yet (e.g. your very first quiz), retention is 0 — you haven't been tested on old material yet

---

## How the final number is calculated

The three parts are combined like this:

```
Fitness score = (Accuracy × 50%) + (Consistency × 30%) + (Retention × 20%)
```

**Worked example:**

| Part | Value |
|---|---|
| Accuracy (recent quiz average) | 70 |
| Consistency (3-day streak, daily topic) | ~43 |
| Retention (got all review questions right) | 100 |

```
Score = (70 × 0.5) + (43 × 0.3) + (100 × 0.2)
      = 35 + 13 + 20
      = 68
```

Your fitness score for that topic would be **68**.

The final score is always kept between **0 and 100**.

---

## What does the user see?

On the **dashboard**, each topic card shows:

- Your current fitness score (e.g. **68**)
- Your streak (e.g. **3 days**)
- Whether today's digest and quiz are ready

On the **topic detail page**, a **trend chart** shows how your score has changed over days and weeks — so you can see whether you're genuinely building understanding over time, not just having a good day.

---

## Why does this matter for the app?

Without Fitness Scorer, Know The World would just be "read the news and do a quiz." The score is what makes it feel like **building fitness in a topic** — the core idea behind the app.

It also drives behaviour we want:

- **Accuracy** rewards actually learning from the briefing
- **Consistency** rewards coming back regularly (daily or weekly, whatever you chose)
- **Retention** rewards sticking with a topic long enough for spaced repetition to kick in — not just cramming today's headlines

---

## What it doesn't do (v1)

- It doesn't compare you to other users (no leaderboards)
- It doesn't drop your score for missing a day — your streak might reset elsewhere, but consistency reflects your current streak length, not guilt-tripping
- It doesn't score you for reading the digest — only for completing quizzes
- It isn't fully wired into the app UI yet — the scoring logic is built and tested, but nothing updates your dashboard automatically after a quiz until we hook that up

---

## Related docs

- [Product overview (PRD)](../PRD.md) — full app spec
- Review questions and spaced repetition — see [Review Question Picker](review_question_picker.md)
