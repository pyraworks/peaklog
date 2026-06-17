String normalize(String input) => input
    .trim()
    .toLowerCase()
    .replaceAll('&', 'and')
    .replaceAll(RegExp(r'[-_]'), ' ')
    .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
    .replaceAll(RegExp(r'\s+'), '_')
    .replaceAll(RegExp(r'_+'), '_');
