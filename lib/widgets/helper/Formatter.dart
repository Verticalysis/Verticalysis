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
    (     "JSON", "json", const KvFormatter.json()),
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
  const KvFormatter(
    this.keyPrefix,
    this.keySuffix,
    this.valuePrefix,
    this.valueSuffix,
    this.association,
    this.entryPrefix,
    this.entrySuffix,
    this.fieldDelimiter,
    this.entryDelimiter,
  );

  const KvFormatter.json()
    : keyPrefix = '"',
      keySuffix = '"',
      valuePrefix = '"',
      valueSuffix = '"',
      association = ': ',
      entryPrefix = '{\n  ',
      entrySuffix = '\n}',
      fieldDelimiter = ',\n  ',
      entryDelimiter = ',\n';

  final String keyPrefix;
  final String keySuffix;

  final String valuePrefix;
  final String valueSuffix;

  final String association;

  final String entryPrefix;
  final String entrySuffix;

  final String fieldDelimiter;
  final String entryDelimiter;

  @override
  /// format [data] as follows:
  /// [entryPrefix]
  ///   [keyPrefix] header [keySuffix] [association] [valuePrefix] value [valueSuffix] [fieldDelimiter]
  ///  ... more fields
  /// [entrySuffix] [entryDelimiter]
  /// ... more entries
  ///
  /// for JSON:
  /// {
  ///   "header": "value",
  ///   ... more fields
  /// },
  /// ... more entries
  String format(int startRow, int endRow, Iterable<(String, List<String?>)> data) {
    final res = StringBuffer();

    // Write each row as a JSON object
    for(int row = startRow; row < endRow; row++) {
      res.write(entryPrefix);

      bool firstField = true;
      for(final (columnName, columnValues) in data) {
        if (!firstField) {
          res.write(fieldDelimiter);
        }
        firstField = false;

        res.write(keyPrefix);
        res.write(_escapeJsonString(columnName));
        res.write(keySuffix);

        res.write(association);

        res.write(valuePrefix);
        final value = row < columnValues.length ? columnValues[row] : null;
        res.write(_escapeJsonString(value ?? ''));
        res.write(valueSuffix);
      }

      res.write(entrySuffix);

      if(row < endRow - 1) res.write(entryDelimiter);
    }

    return res.toString();
  }

  static String _escapeJsonString(String input) => input
    .replaceAll('\\', '\\\\')
    .replaceAll('"', '\\"')
    .replaceAll('\n', '\\n')
    .replaceAll('\r', '\\r')
    .replaceAll('\t', '\\t');
}
