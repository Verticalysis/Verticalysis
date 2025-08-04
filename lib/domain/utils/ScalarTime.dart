// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:math' show pow;

typedef CharIter = Iterator<int>;

/// A duration or a time without a reference
extension type const RelativeTime(int us) {
  Duration get duration => Duration(microseconds: us);
  bool get isInvalid => this == RelativeTime.invalid;
  bool get isIncomplete => this == RelativeTime.incomplete;

  /// Parse a [RelativeTime] from the iterator of a char code [Iterable]
  /// Recognizes following formats by heuristics:
  /// - hh:mm:ss.microseconds
  /// -    mm:ss.microseconds
  /// -       ss.microseconds
  /// - hh:mm:ss
  /// -    mm:ss
  /// -       ss
  ///
  /// hh, mm and ss can either be 1 digit or 2 digits
  ///
  /// the microseconds part should be no more than 6 digits
  ///
  /// All formats are allowed to have trailing contents not starting with
  /// digit, dot, colon or comma.
  static RelativeTime parse(CharIter iter, [ bool fromStart = true ]) {
    if(fromStart && !iter.moveNext()) return RelativeTime.incomplete;
    final hhOrMmOrSs = Uint.fromCharCode(iter);
    if(hhOrMmOrSs.isInvalid) return RelativeTime.invalid;
    if(hhOrMmOrSs.isEOS) return RelativeTime(hhOrMmOrSs.fromEOS * _usPers);
    if(hhOrMmOrSs.digitsLTorEq(2)) { // potential hh or mm or ss
      return _parseMmOrSs(iter, hhOrMmOrSs, true);
    } else return RelativeTime(_consumeFraction(iter, hhOrMmOrSs));
  }

  // Consider two families of inputs:
  // hh:mm:ss[.microseconds]
  //    mm:ss[.microseconds]
  // Notice the logic shared by the process after encountering two digits
  // First we determine if the substring starts with a colon or a dot
  // If it's a dot, we are at
  static RelativeTime _parseMmOrSs(CharIter iter, int hhOrMmOrSs, bool recur) {
    final isColon = _consumeExpected(iter, _colon);
    if(isColon == -1) return RelativeTime.incomplete;
    if(isColon == 1) {
      final mmOrSs = Uint.fromCharCode(iter);
      if(mmOrSs.isInvalid) return RelativeTime.invalid;
      if(mmOrSs.isEOS) {
        if(mmOrSs.digitsLTorEq(2)) {
          final ss = 60 * hhOrMmOrSs /* mm */;
          return RelativeTime((ss + mmOrSs.fromEOS /* ss */) * _usPers);
        } else return RelativeTime.invalid;
      } else if(mmOrSs.digitsLTorEq(2)) {
        final sum = hhOrMmOrSs * 60 + mmOrSs;
        if(recur) return _parseMmOrSs(iter, sum /* mm or ss */, false);
        return RelativeTime(_consumeFraction(iter, sum /* ss */));
      } else return RelativeTime.invalid;
    } else return RelativeTime(_consumeFraction(iter, hhOrMmOrSs /* ss */));
  }

  /// consumes the fraction part of the seconds i.e. microseconds
  static int _consumeFraction(CharIter iter, int s) {
    final isDot = _consumeExpected(iter, _dot);
    if(isDot == -1) return -1;
    if(isDot == 1 || _consumeExpected(iter, _comma) == 1) {
      final leading0 = _consumeLeadingZero(iter);
      if(leading0.isInvalid) return -1;
      if(leading0 == -2) return s * _usPers; // fraction part is all zero
      final fraction = Uint.fromCharCode(iter);
      if(fraction.isInvalid) return -1;
      final frac = fraction.isEOS ? fraction.fromEOS : fraction;
      if(!frac.digitsLTorEq(6 - leading0)) return -1; // 1us maximum resolution
      return s * _usPers + _fraction2us(leading0, frac);
    } else return s * _usPers;
  }

  static int _fraction2us(int leading0, int frac) {
    final fractionDigits = frac.digitsLTorEq(1) ? 1 :
      frac.digitsLTorEq(2) ? 2 :
      frac.digitsLTorEq(3) ? 3 :
      frac.digitsLTorEq(4) ? 4 :
      frac.digitsLTorEq(5) ? 5 :
      frac.digitsLTorEq(6) ? 6 : 0;
    int totalDecimalPlaces = leading0 + fractionDigits;
    return frac * (pow(10, 6 - totalDecimalPlaces)) as int;
  }

  /// consumes a single character if it matches [expected]
  /// returns 0 if not match
  /// otherwise return 1 if there are more characters, or -1 if not
  static int _consumeExpected(CharIter iter, int expected) {
    if(iter.current != expected) return 0;
    return iter.moveNext() ? 1 : -1;
  }

  /// consumes all leading zeros in the fraction part
  /// return the number of 0s if there's more character after the last 0
  /// return -1 if the first character is not a digit
  /// return -2 if the string ends after the last 0
  static int _consumeLeadingZero(CharIter iter) {
    if(!iter.current.isDigitCode) return -1;
    int res = 0;
    for(; iter.current == Uint._zeroCharCode; ++res) if(
      !iter.moveNext()
    ) return -2;
    return res;
  }

  static const _colon = 0x3A;
  static const _comma = 0x2C;
  static const _dot = 0x2E;

  static const _usPers = Duration.microsecondsPerSecond;

  static const incomplete = RelativeTime(-2);
  static const invalid = RelativeTime(-1);
}

/// A time relative to the Linux epoch
/// Only time after 00:00:00 Jan 1 1970 can be represented
extension type const AbsoluteTime(int usSinceEpoch) {
  bool get isInvalid => this == RelativeTime.invalid;
  bool get isIncomplete => this == RelativeTime.incomplete;
  DateTime get dateTime => DateTime.fromMicrosecondsSinceEpoch(usSinceEpoch);

  /// Parse a [AbsoluteTime] from the iterator of a char code [Iterable]
  /// Recognizes following formats by heuristics:
  /// - yyyy*mm*dd
  /// - yyyy*mm*dd*RelativeTime
  /// - mm*dd*
  /// - mm*dd*RelativeTime
  ///
  /// If yyyy is missing in the string, pick [year] as the default value
  ///
  /// mm and dd can either be 1 digit or 2 digits
  ///
  /// '*' represents a single non-digit character
  ///
  /// See also [RelativeTime.parse] for valid formats of RelativeTime
  ///
  /// All formats can have trailing contents not starting with digit, dot,
  /// colon and comma.
  static AbsoluteTime parse(CharIter iter, int year) {
    if(!iter.moveNext()) return AbsoluteTime.incomplete;
    final yyyyOrMm = Uint.fromCharCode(iter);
    if(yyyyOrMm == -1) return _consumeMmmDdRt(iter, year);
    if(yyyyOrMm == -2) return AbsoluteTime.incomplete;
    if(yyyyOrMm.digitsLTorEq(2)) { // mm-dd_RelativeTime
      return _consumeDdRt(iter, year, yyyyOrMm /* mm */, true);
    } else if(yyyyOrMm.digitsLTorEq(4)) { // yyyy-mm-dd_RelativeTime
      if(_consumeNonInt(iter) == -1) return AbsoluteTime.incomplete;
      final mm = Uint.fromCharCode(iter);
      if(mm.isInvalid) return _consumeMmmDdRt(iter, yyyyOrMm /* yyyy */);
      if(mm.isEOS) return AbsoluteTime.incomplete;
      if(!mm.digitsLTorEq(2)) return AbsoluteTime.invalid;
      if(_consumeNonInt(iter) == -1) return AbsoluteTime.incomplete;
      return _consumeDdRt(iter, yyyyOrMm /* yyyy */, mm, true);
    } else return AbsoluteTime.invalid;
  }

  /// consume the date and time starting by abbreviated months
  ///
  /// Check [mmm] for valid abbreviations.
  ///
  /// Abbreviations are case-insensitive. Even mixing cases in one abbreviation
  /// is accepted.
  ///
  /// Consumes an extra non-digit character if present after the Mmm part to
  /// be compatible with RFC-3164 chapter 4.1.2
  static AbsoluteTime _consumeMmmDdRt(CharIter iter, int y) {
    int m0 = iter.current.capitalized, m1 = 0, m2 = 0;
    if(!iter.moveNext()) return AbsoluteTime.invalid;
    m1 = iter.current.capitalized;
    if(!iter.moveNext()) return AbsoluteTime.invalid;
    m2 = iter.current.capitalized;
    final m = mmm.indexOf(String.fromCharCodes([ m0, m1, m2 ]));
    if(m == -1) return AbsoluteTime.invalid;
    if(!iter.moveNext()) return AbsoluteTime.invalid;
    if(iter.current.isDigitCode) return _consumeDdRt(iter, y, m + 1, false);
    if(!iter.moveNext()) return AbsoluteTime.invalid;
    if(iter.current.isDigitCode) return _consumeDdRt(iter, y, m + 1, false);
    if(!iter.moveNext()) return AbsoluteTime.invalid;
    return _consumeDdRt(iter, y, m + 1, false);
  }

  /// consumes one or two digits for days and optionally the RelativeTime part
  static AbsoluteTime _consumeDdRt(CharIter iter, int y, int m, bool skipOne) {
    if(skipOne && _consumeNonInt(iter) == -1) return AbsoluteTime.incomplete;
    final dd = Uint.fromCharCode(iter);
    if(dd.isInvalid) return AbsoluteTime.invalid;
    if(dd.isEOS) if(dd.fromEOS.digitsLTorEq(2)) {
      return fromYMDus(y, m, dd.fromEOS, 0);
    } else return AbsoluteTime.invalid;
    if(!dd.digitsLTorEq(2)) return AbsoluteTime.invalid;
    final delim = _consumeNonInt(iter);
    // Trailing content ignored, even if it's a single character
    if(delim == -1) return fromYMDus(y, m, dd, 0);
    final rt = RelativeTime.parse(iter, false);
    // Unrecognized RelativeTime treated as trailing content
    if(rt.isInvalid) return fromYMDus(y, m, dd, 0);
    if(rt.isIncomplete) return AbsoluteTime.incomplete;
    return fromYMDus(y, m, dd, rt.us);
  }

  /// consumes exactly one non-digit character.
  static int _consumeNonInt(Iterator<int> iter) {
    if(!iter.current.isDigitCode) return iter.moveNext() ? 0 : -1;
    return -2;
  }

  static AbsoluteTime fromYMDus(
    int y, int m, int d, int us
  ) => AbsoluteTime(DateTime(y, m, d, 0, 0, 0, 0, us).microsecondsSinceEpoch);

  static int daysInUs(int days) => days * Duration.microsecondsPerDay;

  static const incomplete = AbsoluteTime(-2);
  static const invalid = AbsoluteTime(-1);

  static const mmm = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC"
  ];
}

extension Uint on int {
  static int fromCharCode(Iterator<int> iter) {
    if(!iter.current.isDigitCode) return -1;
    int res = 0;
    do {
      res = res * 10 + iter.current - _zeroCharCode;
      if(!iter.moveNext()) return -res - 2;
    } while(iter.current.isDigitCode);
    return res;
  }

  bool get isEOS => this < -1;
  bool get isInvalid => this == -1;
  bool get isSpace => this == 32;

  int get fromEOS => -(this + 2);

  int get capitalized => this & 0x5F;

  /// When stringfied, whether the length equals to [digits] or shorter
  bool digitsLTorEq(int digits) => this < const [
    1, 10, 100, 1000, 10000, 100000, 1000000
  ][digits];

  bool get isDigitCode => this >= _zeroCharCode && this < _zeroCharCode + 10;
  static const _zeroCharCode = 0x30;
}
