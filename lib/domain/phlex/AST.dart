// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

// Formal ABNF grammar
//
// ; Atomic building‑blocks RFC8259 compatible
//
// ALPHA        =  %x41-5A / %x61-7A   ; A–Z / a–z
// DIGIT        =  %x30-39             ; 0–9
// HEXDIG       =  DIGIT / %x41-46 / %x61-66   ; 0–9 / A–F / a–f
// ESCAPE       =  "\" (
//                  %x22 /          ; "    quotation mark
//                  %x5C /          ; \    reverse solidus
//                  %x2F /          ; /    solidus
//                  %x62 /          ; b    backspace
//                  %x66 /          ; f    formfeed
//                  %x6E /          ; n    newline
//                  %x72 /          ; r    carriage return
//                  %x74 /          ; t    tab
//                  "u" 4HEXDIG     ; uXXXX 4‑hex‑digits
//               )
// STRING       =  DQUOTE *( %x20-21 / %x23-5B / %x5D-10FFFF / ESCAPE ) DQUOTE
// INT          =  DIGIT          ; no leading zeros for simplicity
// FRAC         =  "." 1*DIGIT
// EXP          =  ("e" / "E") [ "+" / "-" ] 1*DIGIT
// NUMBER       =  [ "-" ] INT [ FRAC ] [ EXP ]
//
// ; Basic whitespace (SP, HTAB, CR, LF)
// WS         = *( SP / HTAB / CR / LF )
//
// ; Identifiers: C-style
// identifier  = ALPHA *( ALPHA / DIGIT / "_" )
//
// ; Function call requires: identifier followed by "(" with no intervening WS
// func-call   = identifier "(" [ WS expr *( WS "," WS expr ) WS ] ")"
//
// ; Relationship expressions
// operand     = identifier / literal / primary
// relationship = operand WS operator WS operand
//
// operator    = "=" / "!=" / ">" / "<" / ">=" / "<="
//
// ; Literals (as per JSON)
// literal     = NUMBER / STRING
//
// ; Parenthetical conjunction (AND)
// conjunction = "(" WS expr *( WS "," WS expr ) WS ")"
//
// ; Square-bracket disjunction (OR)
// disjunction = "[" WS expr *( WS "," WS expr ) WS "]"
//
// ; General expression:
// expr        =  relationship / primary
//
// primary     = [ "!" WS ] ( func-call / conjunction / disjunction / primary )
//

enum BinaryOperator {
  eq._("="), ne._("!="), lt._("<"), gt._(">"), le._("<="), ge._(">=");

  const BinaryOperator._(this.literal);
  final String literal;

  factory BinaryOperator(String literal) => BinaryOperator.values.firstWhere(
    (op) => op.literal == literal
  );
}

abstract class PHLEXexpr {
  const PHLEXexpr(/*this.id, */this.position);

  // final int id;
  final int position;

  String get exprType;
  T accept<T>(ASTvisitor<T> visitor);
}

final class ConjunctionExpr extends PHLEXexpr {
  ConjunctionExpr(/*super.id, */super.position, this.children);
  final List<PHLEXexpr> children;

  @override
  String get exprType => "Conjunction";

  @override
  T accept<T>(ASTvisitor<T> visitor) => visitor.visitConjunctionExpr(children);
}

final class DisjunctionExpr extends PHLEXexpr {
  DisjunctionExpr(/*super.id, */super.position, this.children);
  final List<PHLEXexpr> children;

  @override
  String get exprType => "Disjunction";

  @override
  T accept<T>(ASTvisitor<T> visitor) => visitor.visitDisjunctionExpr(children);
}

final class InvocationExpr extends PHLEXexpr {
  InvocationExpr(/*super.id, */super.position, this.function, this.params);
  final List<PHLEXexpr> params;
  final String function;

  @override
  String get exprType => "Function call";

  @override
  T accept<T>(ASTvisitor<T> visitor) => visitor.visitInvocationExpr(this);
}

final class InvertedExpr extends PHLEXexpr {
  InvertedExpr(/*super.id, */super.position, this.operand);
  final PHLEXexpr operand;

  @override
  String get exprType => "Inversion";

  @override
  T accept<T>(ASTvisitor<T> visitor) => visitor.visitInvertedExpr(operand);
}

final class BinaryExpr extends PHLEXexpr {
  BinaryExpr(/*super.id, */super.position, this.op, this.lhs, this.rhs);
  final BinaryOperator op;
  final PHLEXexpr lhs, rhs;

  @override
  String get exprType => "Comparison";

  @override
  T accept<T>(ASTvisitor<T> visitor) => visitor.visitBinaryExpr(this);
}

final class IntegerLiteral extends PHLEXexpr {
  IntegerLiteral(/*super.id, */super.position, this.value);
  final int value;

  @override
  String get exprType => "Integer";

  @override
  T accept<T>(ASTvisitor<T> visitor) => visitor.visitIntegerLiteral(value);
}

final class FloatLiteral extends PHLEXexpr {
  FloatLiteral(/*super.id, */super.position, this.value);
  final double value;

  @override
  String get exprType => "Float";

  @override
  T accept<T>(ASTvisitor<T> visitor) => visitor.visitFloatLiteral(value);
}

final class StringLiteral extends PHLEXexpr {
  StringLiteral(/*super.id, */super.position, this.value);
  final String value;

  @override
  String get exprType => "String";

  @override
  T accept<T>(ASTvisitor<T> visitor) => visitor.visitStringLiteral(value);
}

final class Identifier extends PHLEXexpr {
  Identifier(/*super.id, */super.position, this.identifier);
  final String identifier;

  @override
  String get exprType => "Identifier";

  @override
  T accept<T>(ASTvisitor<T> visitor) => visitor.visitIdentifier(identifier);
}

abstract class ASTvisitor<T> {
  const ASTvisitor();

  T visit(PHLEXexpr expr) => expr.accept(this);

  T visitConjunctionExpr(List<PHLEXexpr> children);
  T visitDisjunctionExpr(List<PHLEXexpr> children);
  T visitInvocationExpr(InvocationExpr expr);
  T visitInvertedExpr(PHLEXexpr operand);
  T visitBinaryExpr(BinaryExpr expr);
  T visitIntegerLiteral(int value);
  T visitFloatLiteral(double value);
  T visitStringLiteral(String value);
  T visitIdentifier(String id);
}
