// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/foundation.dart';

import '../domain/amorphous/EventIntake.dart';
import '../domain/amorphous/EventManifold.dart';
import '../domain/byteStream/ByteStream.dart';
import '../domain/frontend/Columnarizer.dart';
import '../domain/frontend/Framer.dart';
import '../domain/frontend/Scanner.dart';
import '../domain/schema/AttrType.dart';
import '../domain/schema/Attribute.dart';
import '../domain/schema/Schema.dart';

final class PipelineModel extends ChangeNotifier {
  final EventManifold eventManifold;
  final sources = <ByteStream>[];
  final schemas = <Schema>[];

  PipelineModel(this.eventManifold);

  void connect(Schema schema, ByteStream src) {
    final scanner = Scanner(schema);
    final (columnarizer, intake) = setupFrontend(schema);

    src.events >> framer >> scanner >> columnarizer >> intake >> eventManifold;

    schemas.add(schema);
    sources.add(src);
    notifyListeners();
  }

  void mount(EventIntake intake) => eventManifold.mount(intake);

  void discard() => eventManifold.close();

  void resume() => eventManifold.resume();

  void pause() => eventManifold.pause();

  Iterable<Attribute> get declaredAttributes sync* {
    for(final schema in schemas) if(
      schema case final CustomSchema sch
    ) for(final attribute in sch.attributes) yield attribute;
  }

  AttrType getAttrTypeByName(String name) {
    for(final schema in schemas.reversed) if( // check newly added ones first
      schema case CustomSchema sch
    ) if(sch.attributes.lookup(name) case Attribute attr) return attr.type;
    return AttrType.string; // It's from a schemaless source, default to string
  }

  Attribute getAttributeByName(String name) {
    for(final schema in schemas.reversed) if( // check newly added ones first
      schema case CustomSchema sch
    ) if(sch.attributes.lookup(name) case Attribute attr) return attr;
    return Attribute(name, name, AttrType.string);
  }

  Framer get framer => Framer(32768); // TODO: make chunk size configurable

  (Columnarizer, EvIntakeCtor) setupFrontend(Schema schema) => switch(schema) {
    GenericSchema _ => (Columnarizer.bypass(), EvIntakeCtor.schemaless()),
    CustomSchema sch => (
      Columnarizer(sch.srcAttrs, sch.nonVoidAttrs),
      EvIntakeCtor(sch.attributes.map((dst) => dst.type.toAphAttr(dst.name)))
    )
  };
}
