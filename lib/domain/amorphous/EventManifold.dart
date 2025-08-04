// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'Index.dart';
import 'EventIntake.dart';
import 'Projection.dart';
import 'SparseVector.dart';

/// Also handles all uncaught exceptions in the source stream which propagate
/// all the way down to the receiving [EventIntake].
final class EventManifold {
  EventManifold(this.onError);

  void mount(EventIntake intake) {
    _head = intake..setup(_append, onError, _onClose, _head);
    /*for(final (name, type) in intake.schema) {
      _columns[name] = type.allocVector(size);
    }*/
  }

  /// Merge [lhsAttr] and [rhsAttr] into one column and preserve the name of
  /// [lhsAttr]. [lhsAttr] and [rhsAttr] should have the same type, otherwise
  /// an exception is raised. If both [lhsAttr] and [rhsAttr] are sorted, the
  /// order is retained in the resultant column.
  void merge(String lhsAttr, String rhsAttr) {

  }

  /// Close all Streams sunken by this [EventManifold]
  void close() => _head?.close();

  /// Pause all Streams sunken by this [EventManifold]
  void pause() => _head?.pause();

  /// Resume all Streams sunken by this [EventManifold]
  void resume() => _head?.resume();

  // Append the entries of an incoming chunk of events to the store
  void _append((Events, int) events, EventIntake src) {
    List<String>? newColumns = null;
    final ((columns, deltaSize), oldSize) = (events, size);
    for(final (attr, entries) in columns) _columns.putIfAbsent(attr, () {
      (newColumns ??= []).add(attr);
      return src.getAttr(attr).allocVector(oldSize);
    }).addAll(entries);
    for(final entries in _columns.values) entries.length = deltaSize + oldSize;
    _onChange(SkippedIndex(IotaIndex(deltaSize), oldSize));

    if(newColumns case List<String> cols) onNewColumns(cols);
  }

  Projection expose(bool monitor) {
    final res = Projection(_columns, IotaIndex(size));
    _onChange = monitor ? res.notify : _onChange;
    return res;
  }

  int get size => _columns.values.isEmpty ? 0 : _columns.values.first.length;

  void Function() _onClose  = () {};
  void Function(Object? error, StackTrace trace) onError;
  void Function(Index index) _onChange = (_) {};
  void Function(List<String> attribute) onNewColumns = (_) {};

  final _columns = <String, SparseVector<Comparable?>>{};
  EventIntake? _head;
}

extension RedirToManifold on EventIntake {
  EventManifold operator >> (
    EventManifold rhs
  ) => rhs..mount(this);
}
