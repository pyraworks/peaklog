# Content Rules

Established rules governing how user-generated content may and may not be used in application logic.

---

## Rule #1 — Category is Presentation Data

Categories are user-defined organizational labels.

Categories may only be used for:
- Display and rendering
- List grouping and filtering
- Search and discovery

Categories must never be used for:
- Application behavior decisions
- Business rule evaluation
- UI visibility logic
- Validation logic
- Record type detection
- Unit selection
- Feature gating

### Forbidden patterns

```dart
// Never branch on category name
if (category == 'Run') { ... }
if (categoryId == Category.runId) { ... }

// Never use category to show/hide UI elements
if (exercise.category == 'Weightlifting') showWeightInput();
```

### Approved patterns

```dart
// Display only
Text(exercise.categoryName)

// Grouping
exercises.groupBy((e) => e.categoryId)
```

---

## Rule #2 — Exercise Name is User Content

Exercise names are user-generated content. They have no semantic meaning to the application.

Application behavior must be driven by explicit state — never inferred from user-generated text.

### What this means

- No `RecordType` detection from exercise names
- No unit detection from exercise names
- No logic based on string matching against exercise names
- No `switch` or `if` on `exercise.displayName` or `exercise.normalizedName`

### Forbidden patterns

```dart
// Never infer RecordType from name
if (exercise.displayName.contains('Run')) return RecordType.distance;
if (exercise.normalizedName.startsWith('squat')) return RecordType.weight;
switch (exercise.displayName.toLowerCase()) { ... }

// Never infer unit from name
if (name.contains('km')) useDistanceUnit();
```

### Approved patterns

```dart
// Drive behavior from explicit state
switch (exercise.recordType) { ... }              // explicit field
final unit = exercise.baseUnit;                   // explicit field
final unit = ref.watch(unitSettingsProvider);     // user setting
```

---

## Rule #3 — Behavior from Explicit State Only

Application behavior must always be driven by one of:

| Source | Example |
|--------|---------|
| `RecordType` | `weight / distance / forTime / amrap` |
| `Exercise.baseUnit` | unit set explicitly in Exercise Edit |
| `UnitSettings` | user's global weight unit preference |
| Explicit feature flags | stored configuration |

User-generated text (names, notes, categories) is never a valid source of behavioral decisions.

---

## Auto-Correction Rule

Exercise name normalization is used only for deduplication and search matching — never for behavior inference.

Matching order:
1. `normalizedName` exact match
2. Alias table lookup
3. Levenshtein distance suggestion

On match: show recommendation UI. **Never auto-correct.** The user decides.
