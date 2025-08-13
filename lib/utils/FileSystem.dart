// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:io';

extension type Path(String path) {
  int get fileNameStart => path.lastIndexOf(Platform.pathSeparator) + 1;
  int get fileNameEnd => path.indexOf(".", fileNameStart);

  String get fileName => path.substring(fileNameStart);

  String get trunk => path.substring(fileNameStart, fileNameEnd);

  String get extName => switch(fileNameEnd + 1) {
    0 => "",
    final int extensionStart => path.substring(extensionStart)
  };
}

extension DirectoryEnhancements on Directory {
  String get sep => Platform.pathSeparator;
  Future<Directory> createChild(String subdir) => Directory(
    "$path$sep$subdir"
  ).create(recursive: true);
}
