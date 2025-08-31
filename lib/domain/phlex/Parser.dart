// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'AST.dart';

final class PHLEXparser {
  final String source;
  int _pos = 0;

  static const _EIDkeyword = "var";

  PHLEXparser(this.source);

  PHLEXexpr parse() {
    _skipWS();
    final expr = _parseExpr();
    _skipWS();
    if(_pos != source.length) {
      throw FormatException("Unexpected input at position $_pos");
    }
    return expr;
  }

  PHLEXexpr _parseExpr() {
    _skipWS();
    final beg = _pos;
    final lhs = _parseOperand();

    _skipWS();
    final saved = _pos;

    final op = _peekOperator();
    if(op != null) {
      _pos = saved; // reset before actual parse
      final inverted = lhs is InvertedExpr;
      final cleanLhs = inverted ? lhs.operand : lhs;

      final parsedOp = _parseOperator();
      _skipWS();
      final rhs = _parseOperand();

      return BinaryExpr(beg, parsedOp, cleanLhs, rhs);
    }

    return lhs;
  }

  BinaryOperator? _peekOperator() {
    const operators = ['!=', '>=', '<=', '=', '<', '>'];

    _skipWS();
    for(final op in operators) if(
      _pos + op.length <= source.length && source.substring(
        _pos, _pos + op.length
      ) == op
    ) return BinaryOperator(op);

    return null;
  }

  PHLEXexpr _parseOperand([ bool allowLiteral = true ]) {
    _skipWS();
    if(_peek() == '!') {
      final beg = _pos++;
      _skipWS();
      final inner = _parseOperand(false);
      return InvertedExpr(beg, inner);
    } else return _parsePrimaryOrLiteral(allowLiteral);
  }

  PHLEXexpr _parsePrimaryOrLiteral(bool allowLiteral) {
    final ch = _peek();
    final beg = _pos;
    if(ch == '(') return _parseConjunction();
    if(ch == '[') return _parseDisjunction();
    if(_isAlpha(ch)) {
      final ident = _parseIdentifier();
      if(_peek() == '(') return _parseInvocationOrEID(beg, ident.identifier);
      return ident;
    } else if(allowLiteral) {
      if(ch == '"') return _parseString();
      if(RegExp(r'[0-9\-]').hasMatch(ch)) return _parseNumber();
      throw FormatException("Unexpected operand at position $beg");
    } else throw FormatException(
      "Expected primary expression at position $beg"
    );
  }

  Identifier _parseIdentifier() {
    _skipWS();
    final start = _pos;
    if(!_isAlpha(_peek())) {
      throw FormatException("Invalid identifier at position $_pos");
    }
    while(_pos < source.length &&
      RegExp(r'[a-zA-Z0-9_]').hasMatch(source[_pos])) {
      _pos++;
    }
    return Identifier(start, source.substring(start, _pos));
  }

  /// Parse an invocation expression or an Explicit Identifier Declaration.
  ///
  /// As the result type of an EID varies with the *value* but not the type of
  /// the argument, it's not possible to infer the type in overload resolution.
  /// To facilitate static type analysis, the semantic difference between EID
  /// and invocation is handled in the parsing stage.
  PHLEXexpr _parseInvocationOrEID(int beg, String name) {
    if(!_match('(', skipWS: false)) throw FormatException(
      "Expected '(' after function name at position $_pos"
    ); // white space between function name and argument list is not permitted

    final isEID = name == _EIDkeyword;
    _skipWS();
    if(_peek() == ')') {
      _pos++;
      if(isEID) throw FormatException(
        "Expected an identifier string at position $_pos"
      ); else return InvocationExpr(beg, name, const []);
    }

    final args = <PHLEXexpr>[];
    while(_pos < source.length) {
      args.add(_parseExpr());
      _skipWS();
      if(_match(')')) return isEID ?
        _eid(beg, args) :
        InvocationExpr(beg, name, args);
      if(!_match(',')) throw FormatException(
        "Expected ',' between arguments at position $_pos"
      );
      _skipWS();
    }

    throw FormatException(
      "Expected ')' at position $_pos"
    );
  }

  PHLEXexpr _eid(int beg, List<PHLEXexpr> args) {
    if(args.length > 1) throw FormatException(
      "Extraneous identifier names at position $_pos: only one allowed, "
      "${args.length} supplied."
    ); else if(args.first case final StringLiteral string) {
      return Identifier(beg, string.value);
    } else throw FormatException(
      "Unexpected ${args.first.exprType} at position $_pos: "
      "Identifier must be declared with a string literal."
    );
  }

  PHLEXexpr _parseConjunction()  => _parseComposition(
    ConjunctionExpr.new, "(", ")"
  );

  PHLEXexpr _parseDisjunction() => _parseComposition(
    DisjunctionExpr.new, "[", "]"
  );

  PHLEXexpr _parseComposition(PHLEXexpr constructor(
    int beg, List<PHLEXexpr> subExprs
  ), String starting, String closing) {
    final beg = _pos;
    if(!_match(starting)) throw FormatException(
      "Expected $starting for disjunction at position $_pos"
    );

    _skipWS();
    if(_peek() == closing) {
      _pos++;
      return constructor(beg, []);
    }

    final subExprs = <PHLEXexpr>[];
    while(_pos < source.length) {
      subExprs.add(_parseExpr());
      _skipWS();
      if(_match(closing)) return subExprs.isNotEmpty ?
        constructor(beg, subExprs) :
        throw FormatException("Expected subexpressions at position $_pos");
      if(!_match(',')) throw FormatException(
        "Expected ',' between subexpressions at position $_pos"
      );

      _skipWS();
    }
    throw FormatException(
        "Expected '$closing' at position $_pos"
    );
  }

  BinaryOperator _parseOperator() {
    final op = _matchOneOf(['!=', '>=', '<=', '=', '<', '>']);
    return BinaryOperator(op);
  }

  String _matchOneOf(List<String> options) {
    for (final option in options) {
      final end = _pos + option.length;
      if(end <= source.length && source.substring(_pos, end) == option) {
        _pos = end; // consume it
        return option;
      }
    }
    throw FormatException(
      'Expected one of ${options.join(', ')}', source, _pos
    );
  }

  PHLEXexpr _parseNumber() {
    final start = _pos;
    if(_peek() == '-') _pos++;

    if(!_consumeDigits()) {
      throw FormatException("Invalid number at position $_pos");
    }

    if(_peek() == '.') {
      _pos++;
      if(!_consumeDigits()) {
        throw FormatException("Invalid float at position $_pos");
      }

      if(_peek().toLowerCase() == 'e') {
        _pos++;
        if(_peek() == '+' || _peek() == '-') _pos++;
        if(!_consumeDigits()) {
          throw FormatException("Invalid exponent at position $_pos");
        }
      }

      return FloatLiteral(start, double.parse(source.substring(start, _pos)));
    }

    if(_peek().toLowerCase() == 'e') {
      _pos++;
      if(_peek() == '+' || _peek() == '-') _pos++;
      if(!_consumeDigits()) {
        throw FormatException("Invalid exponent at position $_pos");
      }
      return FloatLiteral(start, double.parse(source.substring(start, _pos)));
    }

    return IntegerLiteral(start, int.parse(source.substring(start, _pos)));
  }

  PHLEXexpr _parseString() {
    final beg = _pos;
    if(!_match('"')) {
      throw FormatException("Expected string at position $_pos");
    }

    final buffer = StringBuffer();
    while(_pos < source.length) {
      final ch = _next();
      if(ch == '"') return StringLiteral(beg, buffer.toString());
      if(ch != '\\') {
        buffer.write(ch);
        continue;
      }

      if(_pos >= source.length) break;

      final esc = _next();
      switch (esc) {
        case '"':
          buffer.write('"');
          break;
        case '\\':
          buffer.write('\\');
          break;
        case '/':
          buffer.write('/');
          break;
        case 'b':
          buffer.writeCharCode(0x08);
          break;
        case 'f':
          buffer.writeCharCode(0x0C);
          break;
        case 'n':
          buffer.write('\n');
          break;
        case 'r':
          buffer.write('\r');
          break;
        case 't':
          buffer.write('\t');
          break;
        case 'u':
          if(_pos + 4 > source.length) {
            throw FormatException("Invalid \\uXXXX escape at position $_pos");
          }
          final hex = source.substring(_pos, _pos + 4);
          if(!RegExp(r'^[0-9a-fA-F]{4}$').hasMatch(hex)) {
            throw FormatException("Invalid Unicode escape at position $_pos");
          }
          buffer.writeCharCode(int.parse(hex, radix: 16));
          _pos += 4;
          break;
        default: throw FormatException(
          "Unknown escape sequence \\$esc at position $_pos"
        );
      }
    }

    throw FormatException("Unterminated string literal at position $_pos");
  }

  bool _consumeDigits() {
    var start = _pos;
    while(_pos < source.length && RegExp(r'\d').hasMatch(source[_pos])) {
      _pos++;
    }
    return _pos > start;
  }

  bool _match(String char, {bool skipWS = true}) {
    if(skipWS) _skipWS();
    if(_peek() == char) {
      _pos++;
      return true;
    }
    return false;
  }

  void _skipWS() {
    while(
      _pos < source.length && RegExp(r'[\t\n\r ]').hasMatch(source[_pos])
    ) _pos++;
  }

  String _peek() => _pos < source.length ? source[_pos] : '\x00';

  String _next() => source[_pos++];

  bool _isAlpha(String ch) => RegExp(r'[a-zA-Z]').hasMatch(ch);
}
