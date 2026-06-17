# PeakLog ShareCreation Spec (Stage 8)

**Status:** Approved 2026-06-03 with 3 modifications.

---

## Modifications from review

1. `OverlayOptions.showPr` → `showValue` — applies to all record types (weight/time/distance/rounds).
2. ExportScreen widget separation — extract: `_ExportPreview`, `_RatioSelector`, `_MediaPicker`, `_FrameSelector`, `_OverlayToggles`, `_ExportActions`.
3. `ShareCreationState.recordId` — add to the data class.

---

## ShareCreationState (ephemeral, no DB)

```dart
class ShareCreationState {
  final String recordId;      // source record
  final String exerciseId;
  final FrameStyle mode;      // clean | rough
  final ExportAspectRatio ratio;
  final String? mediaPath;
  final bool isVideo;
  final bool showExerciseName;
  final bool showValue;       // was showPr
  final bool showDate;
  final bool showDaysSincePB;
}
```

---

## ffmpeg integration

```
[image export]
RepaintBoundary → toImage() → PNG bytes → Gal.putImage(album:'PeakLog')

[video export]
① overlayOnly=true → overlay.png (temp)
② ffmpeg: -i input_video -i overlay.png -filter_complex overlay -preset ultrafast → output.mp4
③ Gal.putVideo(output.mp4)

[share]
PNG → ShareXFiles([XFile(path)]) + sharePositionOrigin (iPad box)
```

---

## Widget structure after refactor

```
ExportScreen (_ExportScreenState owns all mutable state)
  build():
    Scaffold
      _ExportPreview       — display only, receives all render params
      Container (options)
        _RatioSelector     — receives selected + onChanged
        _MediaPicker       — receives file state + callbacks
        _FrameSelector     — receives selected + onChanged
        _OverlayToggles    — receives OverlayOptions + onChanged
        _ExportActions     — receives callbacks + isExporting
```
