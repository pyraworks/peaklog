import 'dart:ui';

/// Display order matches the chip row: Story → Feed → Square → Landscape → Original.
enum ExportAspectRatio { story, feed, square, landscape, original }

extension ExportAspectRatioX on ExportAspectRatio {
  String get label => switch (this) {
    ExportAspectRatio.story     => '9:16',
    ExportAspectRatio.feed      => '4:5',
    ExportAspectRatio.square    => '1:1',
    ExportAspectRatio.landscape => '4:3',
    ExportAspectRatio.original  => 'Original',
  };

  /// Width / height ratio used for preview sizing and layout.
  double get ratio => switch (this) {
    ExportAspectRatio.story     => 9.0 / 16.0,
    ExportAspectRatio.feed      => 4.0 / 5.0,
    ExportAspectRatio.square    => 1.0,
    ExportAspectRatio.landscape => 4.0 / 3.0,
    // TODO(future): Original should match the source media's aspect ratio when
    // background media is loaded. For now it falls back to Story (9:16).
    ExportAspectRatio.original  => 9.0 / 16.0,
  };

  /// Full-resolution export canvas size.
  Size get exportSize => switch (this) {
    ExportAspectRatio.story     => const Size(1080, 1920),
    ExportAspectRatio.feed      => const Size(1080, 1350),
    ExportAspectRatio.square    => const Size(1080, 1080),
    ExportAspectRatio.landscape => const Size(1080,  810),
    ExportAspectRatio.original  => const Size(1080, 1920),
  };
}

enum FrameStyle { clean, rough }

class OverlayOptions {
  final bool showName;
  final bool showValue;
  final bool showDate;
  final bool showDaysSince;

  const OverlayOptions({
    this.showName = true,
    this.showValue = true,
    this.showDate = true,
    this.showDaysSince = true,
  });

  OverlayOptions copyWith({
    bool? showName,
    bool? showValue,
    bool? showDate,
    bool? showDaysSince,
  }) =>
      OverlayOptions(
        showName: showName ?? this.showName,
        showValue: showValue ?? this.showValue,
        showDate: showDate ?? this.showDate,
        showDaysSince: showDaysSince ?? this.showDaysSince,
      );
}
