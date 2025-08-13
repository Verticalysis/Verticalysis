// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tabbed_view/tabbed_view.dart';

import '../../domain/schema/FlatDirSchList.dart';
import '../../utils/FileSystem.dart';
import '../StartupMode.dart';

final class Launcher {
  final bool _debugMode;
  final Set<String> _schemasList;

  static Future<Launcher> create({
    required bool debugMode,
  }) async {
    try {
      final profileDir = await getProfileDir(debugMode);
      final schList = FlatDirSchSet(await profileDir.createChild("schemas"));

      if(await schList.init() case final String error) {
        // TODO: log and report the error
        return Launcher._(debugMode, {});
      } else return Launcher._(debugMode, schList);
    } catch(e) {
      return Launcher._(debugMode, {});
    }
  }

  Launcher._(this._debugMode, this._schemasList);

  Widget launch(
    TabData tab, { String src = ""}
  ) => StartupMode(_schemasList, tab, src: src);

  static Future<Directory> getProfileDir(
    bool temporary
  ) async => switch(temporary) {
    false => await getApplicationDocumentsDirectory(),
    true  => await getTemporaryDirectory()
  }.createChild(".verticalysis");
}
