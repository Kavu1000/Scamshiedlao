extension StringScam on String {
  /// Truncates a URL to show only host + path, max [max] chars.
  /// Mirrors truncateUrl() from history/page.tsx.
  String truncateUrl({int max = 40}) {
    try {
      final uri = Uri.parse(this);
      final path = '${uri.host}${uri.path}';
      return path.length > max ? '${path.substring(0, max)}…' : path;
    } catch (_) {
      return length > max ? '${substring(0, max)}…' : this;
    }
  }

  /// Formats a scam_type snake_case string for display.
  /// e.g. 'job_scam' → 'Job Scam'
  String formatScamType() {
    return replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
