# Development Log

PeakLog development journal. One file per session or date.

---

## Format

Create a new file named `YYYY-MM-DD.md` (or `YYYY-MM-DD-topic.md` for focused sessions).

```markdown
# YYYY-MM-DD

## Features

* Short description of what was added and why.

## Bug Fixes

* What broke, what caused it, how it was fixed.

## Architecture Decisions

* Decision made, alternatives considered, reason chosen.
* Link to docs/architecture/ if a rule was established.

## Notes

* Observations, dead ends, deferred ideas.
* Anything that would be useful to remember in a future session.
```

---

## Guidelines

**Features:** Describe the user-facing change, not the implementation. "Added This is my PR! label when no PB exists" not "Added `_FirstPrLabel` widget to `add_record_sheet.dart`."

**Bug Fixes:** Include the root cause. "Fix: phosphor_flutter incompatible with Flutter 3.44.1 (`IconData` is now `final class`) — replaced with Material Icons."

**Architecture Decisions:** These are the most valuable entries. Capture the reasoning, not just the outcome. If a new rule was added to `docs/architecture/`, note it here.

**Notes:** Low-friction. A bullet point is enough. Better to capture a half-formed thought than to lose it.

---

## Index

| Date | Topics |
|------|--------|
| *(entries will appear here)* | |
