// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:async';
import 'dart:io';

import 'ByteStream.dart';

final class SubprocStream extends RecoverableByteStream {
  final String command;
  bool interrupted = true;
  InterruptNotifier onInterrupted;

  SubprocStream(this.command, this.onInterrupted);

  @override
  String get identifier => command;

  @override
  String get descriptor => command.split(' ').first;

  @override
  Stream<List<int>> get events async* {
    Process process = await start();
    interrupted = false;

    do try {
      if(interrupted) {
        process = await start();
        interrupted = false;
      }
      await for(final bytes in process.stdout) yield bytes;
      await process.exitCode;
    } on Exception catch(e) {
      process.kill();
      interrupted = true;
      final recover = Completer<bool>();
      onInterrupted(identifier, e, recover);
      if(!await recover.future) interrupted = false;
    } while(interrupted);
  }

  Future<Process> start() async {
    final parts = command.split(' ');
    final executable = parts.first;
    final arguments = parts.skip(1).toList();
    return Process.start(executable, arguments);
  }
}
