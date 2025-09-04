// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'Attribute.dart';
import 'AttrType.dart';
import 'CustomFormat.dart';
import '../frontend/codecvt/Encoding.dart';
import '../frontend/parser/Combinatorial.dart';
import '../utils/TaggedMultiset.dart';

export 'CustomFormat.dart'show CapturedMatchers;

final class EmptyAttributesException implements Exception {
  const EmptyAttributesException();
}

final class MissingSectionException implements Exception {
  MissingSectionException(
    Iterable<String> found, this.parent
  ): missing = requiredSections[parent]!.where(
    (section) => !found.contains(section)
  );

  final Iterable<String> missing;
  final String parent;

  static const requiredSections = {
    "top level": ["Source", "Attributes"],
    "Source": ["format"],
    "Attributes": ["name", "type"],
  };
}

final class DuplicatedAttributeException implements Exception {
  DuplicatedAttributeException(Attribute attr): attribute = attr.name;

  final String attribute;
}

final class InvalidLiteralException implements Exception {
  InvalidLiteralException(this.literalType, this.literalName, this.literal);

  final String literalType;
  final String literalName;
  final String literal;
}

sealed class Schema {
  const Schema();
  String get sourceFormat;
  String? get chronologicallySortedBy;
}

final class GenericSchema extends Schema {
  const GenericSchema(this.sourceFormat);

  @override
  final sourceFormat;

  @override
  String? get chronologicallySortedBy => null;
}

final class CustomSchema extends Schema {
  @override
  String? chronologicallySortedBy = null;

  @override
  String sourceFormat = "";
  String sourceDelimiter = "";
  Encoding sourceEncoding = Encoding.utf8;
  CombinatorialParser customFormatParser = phonyCombinatorialParser;
  CapturedMatchers customFormatCaptures = [];

  Iterable<Attribute> get nonVoidAttrs => attributes.where((a) => a.nonVoid);

  final attributes = TaggedMultiset<Attribute>([]);

  final initialWidths = <String, double> {};

  final srcAttrs = <String>[];

  // Validation of the schema is
  void initialize<T>(T ast, R visit<R>(T ast)) {
    final topLevel = visit<Map>(ast);
    T? recognized, filters;
    if(topLevel..retrieve<T>(
      "Recognized", (val) => recognized = val
    )..retrieve<T>(
      "PresetFilters", (val) => filters = val
    ) case {
      "Source":     final T source,
      "Attributes": final T attrs,
    }) {
      _initSource(source, visit);

      for(final attr in visit<List<T>>(attrs)) _initAttr<T>(
        visit<Map>(attr), visit
      );

      if(attributes.isEmpty) throw const EmptyAttributesException();

      if(recognized case final T recognized) for(
        final recogrp in visit<List<T>>(recognized)
      ) _initRecognized(recogrp, visit);

      if(filters case final T filters) for(
        final filter in visit<List<T>>(filters)
      ) _initFilter(filter, visit);

    } else throw MissingSectionException(
      topLevel.keys.cast<String>(), "top level"
    );
  }

  void _initSource<T>(T source, R visit<R>(T ast)) {
    T? /*delimiter, */encoding;
    if(visit<Map>(source)/*..retrieve<T>(
      "delimiter", (val) => delimiter = val
    )*/..retrieve<T>(
      "encoding", (val) => encoding = val
    ) case {
      "format": final T format,
    }) {
      if(encoding case T enc) sourceEncoding = Encoding.of(notFound: (raw) {
        throw InvalidLiteralException("encoding", "Source.encoding", raw);
      }, name: visit<String>(enc));

      if(visit(format) case final Map grammar) {
        sourceFormat = "Custom";
        customFormatParser = MatcherBuilder(
          <R>(node) => visit<R>(node as T)
        ).build(grammar, customFormatCaptures, sourceEncoding.decoder);
      } else sourceFormat = visit<String>(format);

      // sourceDelimiter = delimiter != null ? visit<String>(delimiter) : ;
    } else throw MissingSectionException(
      visit<Map>(source).keys.cast<String>(), "Source"
    );
  }

  void _initAttr<T>(Map attr, R visit<R>(T ast)) {
    T? defaultVal, transform, options, source, width;
    if(attr..retrieve<T>(
      "options", (val) => options = val
    )..retrieve<T>(
      "source", (val) => source = val
    )..retrieve<T>(
      "transform", (val) => transform = val
    )..retrieve<T>(
      "default", (val) => defaultVal = val
    )..retrieve<T>(
      "columnWidth", (val) => width = val
    ) case {
      "name": final T name,
      "type": final T type,
    }) {
      final attrName = visit<String>(name);
      final src = switch(source) {
        final T field => visit<String>(field),
        _ => attrName
      };
      final attr = AttrType.of(
        visit<String>(type),
        (raw) => throw InvalidLiteralException("type", "Attributes.type", raw)
      ).createAttribute(attrName , src);
      if(options != null) ;

      if(transform case final T transform) for(
        final segment in visit<List>(transform)
      ) _initXform(visit<String>(segment as T), attr);

      if(defaultVal case final T val) try {
        attr.defValLiteral = visit<String>(val);
      } on FormatException catch(_) {
        throw InvalidLiteralException(
          attr.type.keyword, "Attributes.default", visit<String>(val)
        );
      }

      if(width case final T width) {
        initialWidths[attrName] = visit<num>(width).toDouble();
      } else if(
        attr.type == AttrType.absoluteTime || attr.type == AttrType.relativeTime
      ) initialWidths[attrName] = 210.0;

      if(!attributes.add(attr)) throw DuplicatedAttributeException(attr);
      if(!srcAttrs.contains(src)) srcAttrs.add(src);
    } else throw MissingSectionException(
      attr.keys.cast<String>(), "Attributes"
    );
  }

  void _initXform(String segment, Attribute attr) {
    if(segment.endsWith("r")) try {
      attr.format.add(RegExpSegment(segment.stripSuffix));
    } on FormatException catch(_) {
      throw InvalidLiteralException("regexp", "Attribute.transform", segment);
    } else if(segment.endsWith("s")) {
      attr.format.add(StringSegment(segment.stripSuffix));
    } else attr.format.add(StringSegment(segment));
  }

  void _initRecognized<T>(T recognized, R visit<R>(T ast)) {
    /* To be implemented
    if(Map.from(visit<Map>(recogrp)) case) {

    }*/
  }

  void _initFilter<T>(T filter, R visit<R>(T ast)) {
    /* To be implemented
    if(Map.from(visit<Map>(filter)) case) {

    }*/
  }
}

extension on String {
  String get stripSuffix => this.substring(0, this.length - 1);
}

extension <T> on Map {
  void retrieve<T>(String key, void f(T? val)) => f(this[key] as T?);
}
