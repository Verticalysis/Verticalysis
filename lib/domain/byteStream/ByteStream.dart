// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'QuiescentFileStream.dart';

enum AddressFamily {
  file(_resolveFile),
  net(_resolveHost);

  const AddressFamily(this.resolve);

  final ByteStream Function(String address) resolve;

  static ByteStream _resolveFile(String addr) => QuiescentFileStream(addr);
  static ByteStream _resolveHost(String addr) {
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
  Future<int> get size;

  static const _badPortNumber = "Port number out of range.";
  static const _badSchema = "Unrecognizable address schema.";

  /// Recognize the type of [address] and return the corresponding [ByteStream]
  ///
  /// Supported address families:
  /// - Unix file paths. Must be absolute path;
  /// - DOS file paths. Must be absolute path;
  /// - UNC file paths;
  /// - IPv4 addresses with the port number after a colon;
  /// - IPv6 addresses with the port number after a colon;
  static ByteStream resolve(String address, [ bool monitored = false ]) {
    bool isFilePath = false, isNetAddress = false;
    String netAddress = "", netPortNum = "";
    if(address.startsWith('/')) { // Unix file path
      isFilePath = true;
    } else if (RegExp(r'^[a-zA-Z]:\\').hasMatch(address)) { // DOS file path
      isFilePath = true;
    } if(address.startsWith(r'\\')) { // UNC file path
      isFilePath = true;
    } else if(RegExp(
      r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+$'
    ).hasMatch(address)) { // IPv4 address
      isNetAddress = true;
      final [ addr, port ] = address.split(':');
      netAddress = addr;
      netPortNum = port;
    } else if(RegExp(
      r'^\[([0-9a-fA-F:]+)\]:(\d+)$'
    ).firstMatch(address) case final RegExpMatch match) { // IPv6 address
      netAddress = match.group(0)!;
      netPortNum = match.group(1)!;
    }

    if(isFilePath) {
      // if(monitored)
      return QuiescentFileStream(address);
    } else if(isNetAddress) {
      int port = int.parse(netPortNum);
      if(port > 65535) throw InvalidAddressException(_badPortNumber);
      throw UnimplementedError();
    } else throw InvalidAddressException(_badSchema);
  }
}

abstract class RecoverableByteStream extends ByteStream {
  bool get interrupted;
  void recover();
}
