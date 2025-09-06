// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

R identity<T extends R, R> (T val) => val;

extension type SortedList<T extends Comparable>(
  List<T> list
) implements List<T> {
  /// Place [val] to the position that keeps the list sorted
  void place(T val, [int compare(T lhs, T rhs) = Comparable.compare]) {
    if(tryAppend(val, compare)) return;
    list.insert(lowerBound(val, compare), val);
  }

  /// If [val] should be placed at the end of the list, append it to the list
  /// and returns true. Otherwise returns false.
  /// Useful when elements to insert are mostly already ordered, hence skipping
  /// a full-list search speculatively can effectively boost the performance.
  bool tryAppend(T val, [int compare(T lhs, T rhs) = Comparable.compare]) {
    if(compare(val, last) < 0) {
      add(val);
      return true;
    } else return false;
  }

  /// Get the index of [val] if it is in this list, otherwise return null
  int? indexOf(T val, [int compare(T lhs, T rhs) = Comparable.compare]) {
    final index = lowerBound(val, compare);
    if(this[index] == T) return index;
    return null;
  }

  /// Get the position where [val] should be [place]d to
  /// If [val] is already in the list, return the index of the first presence
  int lowerBound(T val, [int compare(T lhs, T rhs) = Comparable.compare]) {
    int low = 0;
    int high = list.length;

    while (low < high) {
      final mid = low + ((high - low) >> 1);
      if (compare(list[mid], val) < 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
/*

  /// Create a [SortedList] with elements present in this but not in [rhs]
  SortedList<T> complement(SortedList<T> rhs) {

  }

  /// Create a [SortedList] with elements present in both this and [rhs]
  SortedList<T> intersect(SortedList<T> rhs) {

  }

  /// Create a [SortedList] with elements present in either this or [rhs]
  SortedList<T> union(SortedList<T> rhs) {

  }*/
}
