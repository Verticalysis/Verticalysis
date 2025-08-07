// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../models/FiltersModel.dart';
import 'EventDispatcher.dart';
export 'EventDispatcher.dart';

enum Event<T extends Function> implements Topic<T> {
  newEntries(notifier1<int>),
  newColumns(notifier1<String>),
  selectRegionUpdate(notifier3<int, int, Iterable<(String, List<String?>)>>),
  projectionAppend(notifier1<Filter>),
  projectionRemove(notifier1<Iterable<Filter>>),
  filterRemove(notifier1<Iterable<Filter>>),
  filterAppend(notifier1<Filter>);

  const Event(this._notifer);

  final ChannelNotifer<T> _notifer;

  @override
  ChannelNotifer<T> get notifier => _notifer;
}
