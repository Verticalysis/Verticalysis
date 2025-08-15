// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

import '../../domain/byteStream/ByteStream.dart';
import '../../domain/schema/Schema.dart';
import '../../models/SchemasModel.dart';
import '../../utils/FileSystem.dart';
import 'Events.dart';

extension LoadWithSchema on SchemasModel {
  Future<bool> addSchemaNoThrow(String path) async {
    bool succeed = false;
    try {
      if(addSchema(path)) return succeed = true;
      if(await FlutterPlatformAlert.showAlert(
        windowTitle: 'A schema with the same name already exists.',
        text: 'Would you like to replace it?',
        alertStyle: AlertButtonStyle.yesNo,
        iconStyle: IconStyle.information,
      ) == AlertButton.noButton) return false;
      delSchema(path.split(Platform.pathSeparator).last.split(".").first);
      addSchema(path);
      return succeed = true;
    } on PathNotFoundException catch(e) {
      alertAddSchemaError(_schNotFound, e);
    } on FileSystemException catch(e) {
      alertAddSchemaError(_schOpenError, e);
    } on Exception catch(e) {
      alertAddSchemaError(_unknownError, e);
    } finally {
      return succeed;
    }
  }

  bool getSchemaNoThrow(String name, void onSuccess(Schema _, String name)) {
    bool succeed = false;
    try {
      onSuccess(getSchema(name), name);
      succeed = true;
    } on PathNotFoundException {
      alertLoadSchemaError(name, _schNotFound);
    } on FileSystemException catch(e) {
      alertLoadSchemaError(name, "$_schOpenError: ${e.message}");
    } on FormatException catch(e) {
      alertLoadSchemaError(name, "$_schBadFormat. ${e.message}");
    } on EmptyAttributesException catch(_) {
      alertLoadSchemaError(name, "No attribute is declared in "
      "the Attributes section.");
    } on MissingSectionException catch(e) {
      alertLoadSchemaError(name, "Required fields"
      "${e.missing.join()} are missing from section ${e.parent}.");
      rethrow;
    } on DuplicatedAttributeException catch(e) {
      alertLoadSchemaError(name, "Attribute ${e.attribute}"
      " appeared more than once in the schema.");
    } on InvalidLiteralException catch(e) {
      alertLoadSchemaError(name, "${e.literal} is not a valid"
      " ${e.literalType}, required by ${e.literalName}.");
    } catch(e) {
      alertLoadSchemaError(name, "$_unknownError: $e");
      rethrow;
    } finally {
      return succeed;
    }
  }

  static void alertAddSchemaError(
    String reason, Exception raw
  ) => FlutterPlatformAlert.showAlert(
    windowTitle: 'Error: Failed to register schema!',
    text: reason,
    alertStyle: AlertButtonStyle.ok,
    iconStyle: IconStyle.error,
  );

  static void alertLoadSchemaError(
    String schema, String msg
  ) => FlutterPlatformAlert.showAlert(
    windowTitle: 'Error: Failed to load $schema!',
    text: msg,
    alertStyle: AlertButtonStyle.ok,
    iconStyle: IconStyle.error,
  );

  static GenericSchema? alertRresolveSchemaError(String msg) {
    FlutterPlatformAlert.showAlert(
      windowTitle: 'Error: Failed to infer source format!',
      text: msg,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
    return null;
  }

  static GenericSchema? resolveGenericSchema(
    String fileName
  ) => switch(Path(fileName).extName.toLowerCase()) {
    "csv" => GenericSchema("csv"),
    "" => alertRresolveSchemaError("No file extension found."),
    final String ext => alertRresolveSchemaError("Unknown format $ext."),
  };

  static const _schNotFound = "Schema file not found";
  static const _schOpenError = "Failed to open the schema file";
  static const _schBadFormat = "Failed to parse the schema file";
  static const _unknownError = "Unknown error";
}

extension ByteStreamLoader on ByteStream {
  String get resourceName => Uri.parse(identifier).pathSegments.last;

  /// The label to be displayed as the title of the tab
  String label(String schemaName) => "$resourceName - $schemaName";

  static void load(AddressFamily type, String path, void onSuccess(
    ByteStream stream, Channel strmIntr
  )) {
    final strmIntr = Channel(Event.sourceLinkDown);
    try {
      onSuccess(type.resolve(path, strmIntr.notify), strmIntr);
    } on InvalidAddressException catch(e) {
      alertOpenStreamError("Not a valid address: ${e.reason}");
    } catch(e) {
      alertOpenStreamError("Unknown error: $e");
      rethrow;
    }
  }

  static void alertOpenStreamError(
    String msg
  ) => FlutterPlatformAlert.showAlert(
    windowTitle: 'Error: Failed to open resource',
    text: msg,
    alertStyle: AlertButtonStyle.ok,
    iconStyle: IconStyle.error,
  );
}

extension SchemaName on GenericSchema {
  String get name => "Schemaless${sourceFormat.toUpperCase()}";
}

extension GetPath on FilePickerResult {
  String get path => this.files.single.path!;
}
