// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:io';

import 'ByteStream.dart';

final class QuiescentFileStream extends ByteStream {
  QuiescentFileStream(this._path);

  final String _path;

  @override
  Stream<List<int>> get events => File(_path).openRead();

  @override
  String get identifier => _path;

  @override
  Future<int> get size => File(_path).length();
}
