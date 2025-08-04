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

  static Iterable<(String, FormatFunc)> get formatters => _formatters.map(
    match2((name, formatter) => (name, formatter.format))
  );

  static const _formatters = [
    ("Plaintext", AlignedFormatter(3, "\n", "", false)),
    ("JSON", KvFormatter()),
    ("CSV", DelimitedFormatter(",", "\n", true))
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
  String format(int startRow, int endRow, Iterable<(String, List<String?>)> data) {
    // TODO: implement format
    throw UnimplementedError();
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
