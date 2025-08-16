// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:async';

import 'QuiescentFileStream.dart';
import 'SocketStream.dart';

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
  static ByteStream _resolveHost(String addr, InterruptNotifier notifier) {
    try {
      final uri = Uri.parse(addr);
      if(uri.isScheme("TCP")) {
        if(!uri.hasPort) throw InvalidAddressException("Missing port number");
        if(uri.port > 65536) throw InvalidAddressException("Port number out of range");
        return TCPStream(uri, notifier);
      } else throw InvalidAddressException("Unsupported protocol: ${uri.scheme}");
    } on FormatException catch(e) {
      throw InvalidAddressException(e.message);
    }
  }
}

final class InvalidAddressException implements Exception {
  InvalidAddressException(this.reason);
  final String reason;
}

abstract class ByteStream {
  /// An internal label uniquely identifies the source session-wide
  String get identifier;
  /// A shorter, informative label visible to the user, in places like the tab
  String get descriptor;
  /// Stream of byte sequences
  Stream<List<int>> get events;
}

abstract class RecoverableByteStream extends ByteStream {
  bool get interrupted;
}
