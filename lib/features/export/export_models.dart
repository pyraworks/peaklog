import 'dart:ui';

enum ExportAspectRatio { square, portrait, story }

extension ExportAspectRatioX on ExportAspectRatio {
  String get label => const ['1:1', '4:5', '9:16'][index];

  double get ratio {
    switch (this) {
      case ExportAspectRatio.square:   return 1.0;
      case ExportAspectRatio.portrait: return 4.0 / 5.0;
      case ExportAspectRatio.story:    return 9.0 / 16.0;
    }
  }

  Size get exportSize {
    switch (this) {
      case ExportAspectRatio.square:   return const Size(1080, 1080);
      case ExportAspectRatio.portrait: return const Size(1080, 1350);
      case ExportAspectRatio.story:    return const Size(1080, 1920);
    }
  }
}

enum FrameStyle { clean, rough }

class OverlayOptions {
  final bool showName;
  final bool showPr;
  final bool showDate;
  final bool showDaysSince;

  const OverlayOptions({
    this.showName = true,
    this.showPr = true,
    this.showDate = true,
    this.showDaysSince = true,
  });

  OverlayOptions copyWith({
    bool? showName,
    bool? showPr,
    bool? showDate,
    bool? showDaysSince,
  }) =>
      OverlayOptions(
        showName: showName ?? this.showName,
        showPr: showPr ?? this.showPr,
        showDate: showDate ?? this.showDate,
        showDaysSince: showDaysSince ?? this.showDaysSince,
      );
}
