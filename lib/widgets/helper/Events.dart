// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:async';

import '../../models/FiltersModel.dart';
import '../helper/MonitorModeController.dart';
import 'EventDispatcher.dart';
export 'EventDispatcher.dart';

enum Event<T extends Function> implements Topic<T> {
  newEntries(notifier1<int>),
  newColumns(notifier1<String>),
  newTrace(notifier1<String>),
  selectRegionUpdate(notifier3<int, int, Iterable<(String, List<String?>)>>),
  projectionAppend(notifier1<Filter>),
  projectionRemove(notifier1<Iterable<Filter>>),
  projectionClear(notifier0),
  filterAppend(notifier1<Filter>),
  selectionAppend(notifier1<int>),
  selectionRemove(notifier1<int>),
  collectionAppend(notifier1<int>),
  collectionRemove(notifier1<int>),
  expandToolView(notifier1<Toolset>),
  sourceLinkDown(notifier3<String, Exception, Completer<bool>>);

  const Event(this._notifer);

  final ChannelNotifer<T> _notifer;

  @override
  ChannelNotifer<T> get notifier => _notifer;
}
