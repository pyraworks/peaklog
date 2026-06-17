extension StringExt on String {
  String toTitleCase() => trim().isEmpty
      ? this
      : split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');
}
