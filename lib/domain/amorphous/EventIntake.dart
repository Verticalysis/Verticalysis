// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:async';

import '../utils/TaggedMultiset.dart';
import 'Attribute.dart';

typedef Events = Iterable<(String, Iterable<Comparable?>)>;

final class EventIntake {
  /// Create an [EventIntake] sinking from [src]
  /// [schema] is taken as an optional hint for the type of attributes
  /// If attributs that don't match the name of any supplied attribute
  /// should default to a type, use an attribute with the empty String
  /// "" as the name to specify it.
  EventIntake(
    Stream<(Events, int)> src, [ Iterable<Attribute> schema = const [] ]
  ): _ctrl = src.listen(null)..pause() {
    _schema.addAll(schema);
  }

  /// Resume all paused [EventIntake] mounted on the same [EventManifold]
  /// Meant to be used internally by [EventManifold]
  void resume() {
    _ctrl.resume();
    _sibling?.resume();
  }

  /// Pause all [EventIntake] mounted on the same [EventManifold]
  /// Meant to be used internally by [EventManifold]
  void pause() {
    if(!_ctrl.isPaused) _ctrl.pause();
    _sibling?.pause();
  }

  /// Close all [EventIntake] mounted on the same [EventManifold]
  /// Meant to be used internally by [EventManifold]
  void close() {
    _sibling?.close();
    _ctrl.cancel();
  }

  /// Mount this [EventIntake] into an [EventManifold]
  /// Meant to be used internally by [EventManifold]
  void setup(void append((Events, int) e, EventIntake src), void onError(
    Object? error, StackTrace trace
  ), void onClose(), EventIntake? next) {
    _ctrl..onData(
      (event) => append(event, this)
    )..onError(onError)..onDone(onClose);
    _sibling = next;
    _ctrl.resume();
  }

  /// Retrieve an attribute by [name] in the schema
  /// Meant to be used internally by [EventManifold]
  Attribute getAttr(String name) => switch(_schema.lookup(name)) {
    final Attribute name => name,
    null => switch(_schema.lookup("")) {
      final Attribute name => name,
      null => Attribute.defaultAttr,
    },
  };

  final _schema = TaggedMultiset<Attribute>([]);
  final StreamSubscription<(Events, int)> _ctrl;
  EventIntake? _sibling;
}

extension type EvIntakeCtor(Iterable<Attribute> schema) {
  EvIntakeCtor.schemaless(): schema = const [];
  EventIntake construct(Stream<(Events, int)> src) => EventIntake(src, schema);
}

extension RedirToEvIntakeCtor on Stream<(Events, int)> {
  EventIntake operator >> (EvIntakeCtor ctor) => ctor.construct(this);
}
