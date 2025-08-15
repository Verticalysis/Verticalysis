// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.


import 'dart:async';
import 'dart:io';

import 'ByteStream.dart';

mixin SocketStream {
  Future<Socket> connect();

  String get identifier;

  bool get interrupted;

  set interrupted(bool _);

  InterruptNotifier get onInterrupted;

  Stream<List<int>> get events async* {
    Socket socket = await connect();
    interrupted = false;

    do try {
      if(interrupted) {
        socket = await connect();
        interrupted = false;
      }
      await for(final bytes in socket) yield bytes;
      socket.close();
    } on Exception catch(e) {
      socket.close();
      interrupted = true;
      final recover = Completer<bool>();
      onInterrupted(identifier, e, recover);
      if(!await recover.future) interrupted = false;
    } while(interrupted);
  }
}

final class TCPStream extends RecoverableByteStream with SocketStream {
  final Uri address;
  bool interrupted = true;
  InterruptNotifier onInterrupted;

  TCPStream(this.address, this.onInterrupted);

  @override
  String get identifier => address.toString();

  Future<Socket> connect() => Socket.connect(address.host, address.port);
}
