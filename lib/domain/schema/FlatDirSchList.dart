// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';
import 'dart:io';

/// Manages user supplied schemas by saving a copy to [_directory]
///
/// The extension in the file name is stripped from the copy so that the list
/// of schemas' names can be obtained by enumerating entries in the directory.
///
/// Serves as an abstraction of the file system only. The semantic of schemas
/// is handled at the model layer.
///
/// Note [FlatDirSchSet] exposes an ordered-container-like facade for easier
/// iteration, but operates as an associative container: [lookup] by the name
/// of the schema returns the file content of that schema.
final class FlatDirSchSet with SetBase<String> {
  FlatDirSchSet(this._directory);

  final Directory _directory;
  final _entriesCache = <String, String> {}; // schema name -> absolute path

  /// Enumerates schemas in [_directory]
  /// Returns an [Future] completes with the details if an error occurs,
  /// otherwise the [Future] completes with null.
  Future<String?> init() async {
    try {
      await for(
        final entity in _directory.list()
      ) if(entity case final File sch) _entriesCache[
        sch.uri.pathSegments.last
      ] = sch.path;
    } catch(e) {
      return e.toString();
    }
    return null;
  }

  @override
  /// Add the schema file at [path] to this [FlatDirSchSet].
  /// If a schema with the same name was added, returns false with the
  /// operation aborted. Otherwise returns true.
  bool add(String path) {
    final sep = Platform.pathSeparator;
    final name = path.split(sep).last.split(".").first;
    final dest = "${_directory.path}$sep$name";
    File(path).copy(dest).ignore(); // TODO: make failures noticeable
    _entriesCache[name] = dest;
    return true;
  }

  @override
  bool contains(Object? element) => switch(element) {
    final String name => _entriesCache.containsKey(name),
    _ => throw TypeError()
  };

  @override
  Iterator<String> get iterator => _entriesCache.keys.iterator;

  @override
  int get length => _entriesCache.length;

  @override
  String? lookup(Object? element) => switch(element) {
    final String name => File(_entriesCache[name]!).readAsStringSync(),
    _ => throw TypeError()
  };

  @override
  bool remove(Object? value) {
    if(_entriesCache[value] case final String path) {
      File(path).deleteSync();
      _entriesCache.remove(value);
      return true;
    } else return false;
  }

  @override
  Set<String> toSet() {
    // TODO: implement toSet
    throw UnimplementedError();
  }
}
