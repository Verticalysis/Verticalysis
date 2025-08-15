// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:async';

import 'QuiescentFileStream.dart';

typedef InterruptNotifier = void Function(
  String streamId,
  Exception reason,
  // if the stream should attempt to recover, complete with true
  Completer<bool> recover
);

enum AddressFamily {
  file(_resolveFile),
  net(_resolveHost);

  const AddressFamily(this.resolve);

  final ByteStream Function(String address, InterruptNotifier _) resolve;

  static ByteStream _resolveFile(
    String addr, InterruptNotifier _
  ) => QuiescentFileStream(addr);
  static ByteStream _resolveHost(String addr , InterruptNotifier notifier) {
    throw UnimplementedError("");
  }
}

final class InvalidAddressException implements Exception {
  InvalidAddressException(this.reason);
  final String reason;
}

abstract class ByteStream {
  String get identifier;
  Stream<List<int>> get events;
}

abstract class RecoverableByteStream extends ByteStream {
  bool get interrupted;
}
