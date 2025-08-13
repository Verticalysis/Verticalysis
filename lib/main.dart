// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:args/args.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter/material.dart' hide Scaffold;

import 'widgets/helper/Launcher.dart';
import 'widgets/Scaffold.dart';
import 'widgets/Style.dart';

void main(List<String> args) async {
  final parser = ArgParser()..addFlag('debug', abbr: "d", defaultsTo: false)
    ..addOption("schema", abbr: "s");

  try {
    /*WidgetsFlutterBinding.ensureInitialized();
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: Color(0xCC222222),
    );*/
    final options = parser.parse(args);
    final launcher = await Launcher.create(debugMode: options.flag('debug'));
    if(options.rest case [ final path, ...final remainder ]) {
      if(remainder.isNotEmpty) return printHints("Only one source can be supplied");
      if(options.option('schema') case final String schema) {

      } else runApp(launch(launcher, src: path));
    } else runApp(launch(launcher));
    doWhenWindowReady(() {
     const initialSize = const Size(800, 600);
     appWindow.minSize = const Size(640, 480);
     appWindow.size = initialSize;
     appWindow.alignment = Alignment.center;
     appWindow.show();
   });
  } catch(e) {

  }
}

void printHints(String? error) => print(
  "${error != null ? error+'\n' : ''}"
  "Usage: verticalysis source-path [OPTION]\n"
  "\n"
  "  -s, --schema=schema-name\n"
  "      open the provided source with the schema of schema-name"
);

Widget launch(Launcher launcher, { String src = "" }) => MaterialApp(
  color: const Color(0x00000000),
  title: 'Flutter Demo',
  theme: lightColorTheme,
  // TODO: darkTheme: ,
  home: Material(child: Scaffold(launcher, src: src)),
);
