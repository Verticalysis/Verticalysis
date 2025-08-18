// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/foundation.dart';

import '../domain/schema/Schema.dart';

/// Provides unified access to custom schemas and built-in schemas
final class SchemasModel extends ChangeNotifier {
  final void Function(CustomSchema schema, String src) parser;
  final Set<String> schList;
  final _schemas = <String, Schema>{};

  SchemasModel(this.schList, this.parser);

  int get length => schList.length + _genericSchema.length;

  Schema getSchema(String name) {
    if(_genericSchema[name] case final GenericSchema schema) return schema;
    if(_schemas[name] case final Schema schema) return schema;
    final schema = CustomSchema();
    parser(schema, schList.lookup(name)!);
    return _schemas[name] = schema;
  }

  /// check [FlatDirSchSet.add] for semantics
  bool addSchema(String path) {
    if(!schList.add(path)) return false;
    notifyListeners();
    return true;
  }

  void delSchema(String name) {
    schList.remove(name);
    notifyListeners();
  }

  Iterable<String> get schemas sync* {
    for(final schema in schList) yield schema;
    for(final MapEntry(key: schema, value: _) in _genericSchema.entries) yield schema;
  }

  static const _genericSchema = {
    "Generic CSV": GenericSchema("csv")
  };
}
