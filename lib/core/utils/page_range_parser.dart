/// Parses human-entered page ranges like "1, 3-5, 10" into a sorted set.
class PageRangeParser {
  static Set<int> parse(String input, {required int totalPages}) {
    final result = <int>{};
    if (input.trim().isEmpty) return result;

    for (final part in input.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains('-')) {
        final bounds = trimmed.split('-');
        if (bounds.length == 2) {
          final start = int.tryParse(bounds[0].trim());
          final end = int.tryParse(bounds[1].trim());
          if (start != null && end != null && start <= end) {
            for (int i = start; i <= end; i++) {
              _addPage(result, i, totalPages);
            }
          }
        }
      } else {
        final page = int.tryParse(trimmed);
        _addPage(result, page, totalPages);
      }
    }

    return result;
  }

  static void _addPage(Set<int> result, int? page, int totalPages) {
    if (page != null && page >= 1 && page <= totalPages) {
      result.add(page);
    }
  }

  static String format(Set<int> pages) {
    if (pages.isEmpty) return '';
    final sorted = pages.toList()..sort();
    final ranges = <String>[];

    int? start;
    int? previous;

    for (final page in sorted) {
      if (start == null) {
        start = page;
        previous = page;
      } else if (page == previous! + 1) {
        previous = page;
      } else {
        if (start == previous) {
          ranges.add(start.toString());
        } else {
          ranges.add('$start-$previous');
        }
        start = page;
        previous = page;
      }
    }

    if (start != null) {
      if (start == previous) {
        ranges.add(start.toString());
      } else {
        ranges.add('$start-$previous');
      }
    }

    return ranges.join(', ');
  }
}
