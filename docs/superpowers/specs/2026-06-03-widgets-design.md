# PeakLog Reusable Widgets Spec (Stage 5)

**Status:** Approved 2026-06-03 with 3 modifications.

---

## Modifications from review

1. SwipeableRow uses flutter_slidable (already in pubspec). Tap → Edit, Swipe end → Share + Delete. Android first-launch hint via SharedPreferences.
2. CategoryBadge takes `label: String`. Caller resolves categoryId → name.
3. OneRMCalculator keeps `_selectedPct` as local StatefulWidget state.

---

## Widget inventory (final)

| File | Widget | Type | Status |
|---|---|---|---|
| `pb_badge.dart` | `PbBadge` | StatelessWidget | modify — add `label` param |
| `exercise_card.dart` | `ExerciseCard` | StatelessWidget | modify — add `pbLabel` |
| `history_row.dart` | `HistoryRow` | StatelessWidget | modify — add `pbLabel` |
| `category_badge.dart` | `CategoryBadge` | StatelessWidget | NEW |
| `personal_best_card.dart` | `PersonalBestCard` | StatelessWidget | NEW |
| `swipeable_row.dart` | `SwipeableRow` | StatefulWidget | NEW |
| `one_rm_calculator.dart` | `OneRMCalculator` | StatefulWidget | NEW |
| `one_rm_table_row.dart` | `OneRMTableRow` | StatelessWidget | NEW |

---

## SwipeableRow

```
Slidable
  endActionPane: DrawerMotion
    SlidableAction(Share, primary blue)
    SlidableAction(Delete, destructive red)
  child: GestureDetector(onTap: onEdit)
    child (HistoryRow or any Widget)
```

Android hint: StatefulWidget checks SharedPreferences `swipe_hint_shown` in `initState`. If false and `Platform.isAndroid`, shows SnackBar after first frame, sets flag.
