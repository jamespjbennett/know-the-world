# Domain docs

Plain-English explanations of how each part of Know The World works.

For the high-level system map see [ARCHITECTURE.md](../ARCHITECTURE.md). These docs describe **behaviour and user impact**, not code structure.

| Domain | What it does |
|---|---|
| [Fitness Scorer](fitness_scorer.md) | Calculates your 0–100 topic fitness score after each quiz |
| [Review Question Picker](review_question_picker.md) | Chooses old questions to revisit in each quiz (~30% review mix) |
| [Quiz Assembler](quiz_assembler.md) | Combines new digest questions + review picks into one ordered quiz |

More domains will be added here as we build them (e.g. digest generation).
