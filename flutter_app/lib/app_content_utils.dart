String normalizeReportText(String? value) {
  if (value == null) return '';

  final cleaned = value
      .replaceAll(RegExp(r'\r\n?|\n'), '\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  if (cleaned.isEmpty) return '';

  return cleaned
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}

List<String> splitIntoReadableParagraphs(String? value, {int maxParagraphs = 4}) {
  final normalized = normalizeReportText(value);
  if (normalized.isEmpty) return const [];

  final paragraphs = normalized
      .split(RegExp(r'\n\s*\n'))
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList();

  if (paragraphs.isEmpty) return [normalized];
  return paragraphs.take(maxParagraphs).toList();
}
