// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/widgets.dart';

extension Scale on Widget {
  Widget scale({
    double? height, double? width
  }) => SizedBox(width: width, height: height, child: FittedBox(child: this));
}

extension PostConstructionCallback<T> on T {
  void postConstruct(void cb(T obj)) => cb(this);
}
