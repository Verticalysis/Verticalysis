// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../utils/EnhancedPatterns.dart';

typedef FormatFunc = String Function(
  int startRow, int endRow, Iterable<(String, List<String?>)> data
);

abstract class Formatter {
  const Formatter();

  String format(int startRow, int endRow, Iterable<(String, List<String?>)> data);

  static Iterable<(String, String, FormatFunc)> get formatters => _formatters.map(
    match3((name, ext, formatter) => (name, ext, formatter.format))
  );

  static const _formatters = [
    ("Plaintext", "txt",  const AlignedFormatter(3, "\n", "", false)),
    (     "JSON", "json", const KvFormatter()),
    (      "CSV", "csv",  const DelimitedFormatter(",", "\n", true))
  ];
}

final class AlignedFormatter extends Formatter {
  const AlignedFormatter(
    this.margin, this.lineBreak, this.delimiter, this.withHeader
  );

  final int margin;
  final String delimiter;
  final String lineBreak;
  final bool withHeader;

  @override
  /// Format [data] with each column aligned to the left and separated by [delimiter]
  String format(int startRow, int endRow, Iterable<(String, List<String?>)> data) {
    final res = StringBuffer();
    List<String?> last = const [];

    // Calculate maximum width for each column
    final columnWidths = <int>[];
    for(final (_, values) in data) {
      int maxWidth = values.isNotEmpty ? values[startRow]?.length ?? 0 : 0;

      for(int row = startRow; row < endRow; row++) {
        final value = values[row] ?? '';
        maxWidth = maxWidth > value.length ? maxWidth : value.length;
      }

      columnWidths.add(maxWidth + margin);
      last = values;
    }

    // Write header if enabled
    if(withHeader) {
      for(final (col, (title, values)) in data.indexed) {
        res.write(title.padRight(columnWidths[col]));
        if(values != last) res.write(delimiter);
      }
      res.write(lineBreak);
    }

    // Write data rows
    for(int row = startRow; row < endRow; row++) {
      bool hasData = false;
      for(final (col, (_, values)) in data.indexed) {
        hasData = true;
        final value = values[row] ?? '';
        res.write(value.padRight(columnWidths[col]));
        if(values != last) res.write(delimiter);
      }
      if(hasData) res.write(lineBreak);
    }

    return res.toString();
  }
}

final class DelimitedFormatter extends Formatter {
  const DelimitedFormatter(this.delimiter, this.lineBreak, this.withHeader, {
    this.escape = identity
  });

  final String delimiter;
  final String lineBreak;
  final bool withHeader;

  final String Function(String _) escape;

  @override
  String format(int startRow, int endRow, Iterable<(String, List<String?>)> data) {
    final res = StringBuffer();
    if(withHeader) res..write(
      data.map(match2((title, _) => title)).join(delimiter)
    )..write(lineBreak);

    for(int i = startRow; i != endRow; ++i) res..write(
      data.map(match2((_, column) => column[i])).join(delimiter)
    )..write(lineBreak);

    return res.toString();
  }

  static String identity(String src) => src;
}

final class KvFormatter extends Formatter {
  const KvFormatter();

  @override
  String format(int startRow, int endRow, Iterable<(String, List<String?>)> data) {
    // TODO: implement format
    throw UnimplementedError();
  }
}
