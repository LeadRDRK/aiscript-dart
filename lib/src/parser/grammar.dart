import 'package:petitparser/petitparser.dart';

// Main
class AiScriptGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref1(_trim, ref0(globalStatements)).end('invalid global statement');

  // General
  Parser name() => (pattern('a-zA-Z_') & pattern('a-zA-Z0-9_').starString()).flatten('name expected');
  Parser nameWithNamespace() => ref0(name) & (char(':') & ref0(name)).star();
  Parser whitespace() => anyOf(' \t\r\n');
  Parser spaceOnly() => anyOf(' \t');
  Parser separator() =>
      (ref1(_trim, ',')) |
      ref0(whitespace).plus();
  
  Parser block() =>
      char('{').skip(after: ref0(whitespace).star()) & ref0(statements) & char('}').skip(before: ref0(whitespace).star());
  
  Parser blockOrStatement() =>
      ref0(block) |
      ref0(statement);

  Parser bracket(String brackets, Parser parser) =>
      char(brackets[0]) & parser & char(brackets[1]);
  
  // for ensuring that some names are not identifiers (true, false, null, etc.)
  Parser notIdentifier() => pattern('^a-zA-Z0-9_') | endOfInput();

  // Specialized trim parser
  Parser _trim(Object input) {
    if (input is Parser) {
      return input.trim(ref0(whitespace));
    } else if (input is String) {
      return _trim(input.toParser());
    }
    throw ArgumentError.value(input, 'Invalid parser');
  }

  // Statement list
  Parser statementsBase(Object input) {
    if (input is Parser) {
      return input.starSeparated(ref0(spaceOnly).star() & newline() & ref0(whitespace).star());
    }
    throw ArgumentError.value(input, 'Invalid statement parser');
  }
  Parser globalStatements() => ref1(statementsBase, ref0(globalStatement));
  Parser namespaceStatements() => ref1(statementsBase, ref0(namespaceStatement));
  Parser statements() => ref1(statementsBase, ref0(statement));

  Parser globalStatement() => ref0(namespace) | ref0(meta) | ref0(statement);
  Parser namespaceStatement() => ref0(varDef) | ref0(fnDef) | ref0(namespace);

  Parser statement() =>
      ref0(varDef) |      // "let" NAME | "var" NAME
      ref0(fnDef) |       // "@"
      ref0(out) |         // "<:"
      ref0(return_) |     // "return"
      ref0(attr) |        // "+"
      ref0(each) |        // "each"
      ref0(for_) |        // "for"
      ref0(loop) |        // "loop"
      ref0(break_) |      // "break"
      ref0(continue_) |   // "continue"
      ref0(assignOrExpr); // Expr "=" | Expr "+=" | Expr "-="
  
  // Expression list
  Parser expr() => 
      ref0(infixOrExpr2);

  Parser expr2() =>
      ref0(if_) |         // "if"
      ref0(fn) |          // "@("
      ref0(chainOrExpr3); // Expr3 "(" | Expr3 "[" | Expr3 "."

  Parser expr3() =>
      ref0(match) |       // "match"
      ref0(eval) |        // "eval"
      ref0(exists) |      // "exists"
      ref0(tmpl) |        // "`"
      ref0(str) |         // "\""
      ref0(num_) |        // "+" | "-" | "1"~"9"
      ref0(boolean) |     // "true" | "false"
      ref0(null_) |       // "null"
      ref0(obj) |         // "{"
      ref0(arr) |         // "["
      ref0(not) |         // "!"
      ref0(identifier) |  // NAME_WITH_NAMESPACE
      ref0(exprInParens);

  Parser exprInParens() =>
      ref0(expr).skip(
        before: char('(') & ref0(whitespace).star(),
        after: ref0(whitespace).star() & char(')')
      );

  // Static literal list
  Parser staticLiteral() =>
      ref0(num_) |        // "+" "1"~"9" | "-" "1"~"9" | "1"~"9"
      ref0(str) |         // "\""
      ref0(boolean) |     // "true" | "false"
      ref0(staticArr) |   // "["
      ref0(staticObj) |   // "{"
      ref0(null_);        // "null"

  // Namespace statement
  Parser namespace() => string('::') &
      ref0(name).skip(before: ref0(whitespace).plus(), after: ref0(whitespace).plus()) &
      ref1(_trim, '{') & ref0(namespaceStatements).optional() & char('}').skip(before: ref0(whitespace).star());

  // Meta statement
  Parser meta() => string('###') & (
      ref0(metaWithName) |
      ref0(metaWithoutName)
  );

  Parser metaWithName() =>
      ref0(name).trim(ref0(spaceOnly), ref0(whitespace)) & ref0(staticLiteral);

  Parser metaWithoutName() =>
      ref0(staticLiteral).skip(before: ref0(spaceOnly).star());

  // Define statement
  Parser varDef() => string('let').or(string('var')) &
      ref0(name).skip(before: ref0(whitespace).plus()) &
      ref0(varType).optional() & ref1(_trim, '=') & ref0(expr);

  Parser varType() =>
      ref1(_trim, ':') & ref0(type);
  
  // Out (syntax sugar for print)
  Parser out() =>
      string('<:').skip(after: ref0(whitespace).star()) & ref0(expr);

  // Attribute statement
  Parser attr() => string('#[') &
      ref1(_trim, ref0(name)) & ref0(staticLiteral).optional() & char(']').skip(before: ref0(whitespace).star());

  // Let declaration for Each and For statements
  Parser letDeclaration() =>
      string('let').skip(after: ref0(whitespace).plus()) & ref0(name);

  // Each statement
  Parser each() => string('each') & (
      ref0(eachWithParens) |
      ref0(eachWithoutParens)
  );

  Parser eachWithParens() =>
      char('(').skip(before: ref0(whitespace).star()) & ref0(letDeclaration) &
      ref1(_trim, ',').optional() & ref0(expr) & char(')').skip(after: ref0(whitespace).star()) & ref0(blockOrStatement);

  Parser eachWithoutParens() =>
      ref0(letDeclaration).skip(before: ref0(whitespace).plus()) & ref1(_trim, ',').optional() &
      ref0(expr).skip(after: ref0(whitespace).plus()) & ref0(blockOrStatement);
  
  // For statement
  Parser for_() => string('for') & (
      ref0(forWithParens) |
      ref0(forWithoutParens)
  );

  // With parentheses
  Parser forWithParens() => char('(').skip(before: ref0(whitespace).star()) & (
      ref0(forVarWithParens) |
      ref0(forTimesWithParens)
  );

  Parser forVarWithParens() =>
      ref0(letDeclaration) &
      (ref1(_trim, '=') & ref0(expr)).optional() & char(',').optional() &
      ref0(expr).skip(before: ref0(whitespace).star()) & char(')').skip(after: ref0(whitespace).star()) & ref0(blockOrStatement);

  Parser forTimesWithParens() =>
      ref0(expr) & char(')').skip(after: ref0(whitespace).star()) &
      ref0(blockOrStatement);

  // Without parentheses
  Parser forWithoutParens() => (
      ref0(forVarWithoutParens) |
      ref0(forTimesWithoutParens)
  )
  .skip(before: ref0(whitespace).plus());

  Parser forVarWithoutParens() =>
      ref0(letDeclaration) &
      (ref1(_trim, '=') & ref0(expr)).optional() & char(',').optional() &
      ref0(expr).skip(before: ref0(whitespace).star(), after: ref0(whitespace).plus()) & ref0(blockOrStatement);

  Parser forTimesWithoutParens() =>
      ref0(expr).skip(after: ref0(whitespace).plus()) &
      ref0(blockOrStatement);
  
  // Return statement
  Parser return_() =>
      string('return').skip(after: ref0(notIdentifier) & ref0(whitespace).star()) & ref0(expr);

  // Loop statement
  Parser loop() =>
      string('loop') & ref1(_trim, '{') & ref0(statements) & char('}').skip(before: ref0(whitespace).star());

  // Break statement
  Parser break_() =>
      string('break') & ref0(notIdentifier).and();

  // Continue statement
  Parser continue_() =>
      string('continue') & ref0(notIdentifier).and();

  // Assign statement
  Parser assignOrExpr() =>
      ref0(expr) & (ref1(_trim, string('+=') | string('-=') | char('=')) & ref0(expr)).optional();

  // Infix expression
  Parser infixOrExpr2() =>
      ref0(expr2) & (ref0(op).skip(before: ref0(infixSp).star(), after: ref0(infixSp).star()) & ref0(expr2)).star();
  
  Parser infixSp() =>
      (char('\\') & newline()) | ref0(spaceOnly);

  Parser op() =>
      string('||') | string('&&') | string('==') | string('!=') | string('<=') | string('>=') |
      anyOf('<>+-*^/%');
  
  Parser not() =>
      char('!') & ref0(expr);

  // Chain
  Parser chainOrExpr3() =>
      ref0(expr3) & (ref0(callChain) | ref0(indexChain) | ref0(propChain)).star();
  
  Parser callChain() =>
      char('(') & ref1(_trim, ref0(callArgs)) & char(')');
  
  Parser callArgs() =>
      ref0(expr).starSeparated(ref0(separator));
  
  Parser indexChain() =>
      char('[') & ref1(_trim, ref0(expr)) & char(']');
  
  Parser propChain() =>
      char('.') & ref0(name);
  
  // If statement
  Parser if_() => string('if').skip(after: ref0(whitespace).plus()) &
      ref0(expr).skip(after: ref0(whitespace).plus()) & ref0(blockOrStatement) &
      (ref0(elseifBlocks).skip(before: ref0(whitespace).plus())).optional() &
      (ref0(elseBlock).skip(before: ref0(whitespace).plus())).optional();
  
  Parser elseifBlocks() =>
      ref0(elseifBlock).plusSeparated(ref0(whitespace).star());
  
  Parser elseifBlock() => string('elif').skip(after: ref0(notIdentifier)) &
      ref1(_trim, ref0(expr)) & ref0(blockOrStatement);

  Parser elseBlock() => string('else').skip(after: ref0(notIdentifier) &
      ref0(whitespace).star()) & ref0(blockOrStatement);
  
  // Match expression
  Parser match() => string('match').skip(after: ref0(notIdentifier)) &
      ref1(_trim, ref0(expr)) & ref1(_trim, '{') &
      ref0(matchCase).plus() &
      ref0(matchDefaultCase).optional() & char('}');

  Parser matchCase() =>
      ref0(expr) & ref1(_trim, '=>') & ref1(_trim, ref0(blockOrStatement));
  
  Parser matchDefaultCase() =>
      char('*') & ref1(_trim, '=>') & ref1(_trim, ref0(blockOrStatement));
  
  // Eval expression
  Parser eval() => string('eval') &
      ref1(_trim, '{') & ref0(statements) & char('}').skip(before: ref0(whitespace).star());
  
  // Exists expression
  Parser exists() => string('exists') & ref0(identifier).skip(before: ref0(whitespace).plus());
  
  // Identifier
  Parser identifier() => ref0(nameWithNamespace).flatten('identifier expected');

  // Template literal
  Parser tmpl() =>
      ref2(bracket, '``', ref0(tmplEmbed).star());
  
  Parser tmplEmbed() =>
      ref0(tmplEsc) |
      ref0(tmplExpr) |
      pattern('^`');
  
  Parser tmplEsc() =>
      string('\\{') |
      string('\\}') |
      string('\\`');

  Parser tmplExpr() =>
      char('{').skip(after: ref0(spaceOnly).star()) & ref0(statements) & char('}').skip(before: ref0(spaceOnly).star());
  
  // String literal
  Parser str() =>
      ref0(strDoubleQuote) |
      ref0(strSingleQuote);
  
  Parser strDoubleQuote() =>
      ref2(bracket, '""', (ref0(strDoubleQuoteEsc) | pattern('^"')).star());

  Parser strSingleQuote() =>
      ref2(bracket, '\'\'', (ref0(strSingleQuoteEsc) | pattern('^\'')).star());

  Parser strDoubleQuoteEsc() => string('\\"');
  Parser strSingleQuoteEsc() => string('\\\'');

  // Number literal
  Parser num_() =>
      ref0(float) |
      ref0(int_);
  
  Parser float() =>
      (pattern('+-').optional() & pattern('1-9') & pattern('0-9').plus() & char('.') & pattern('0-9').plus()) |
      (pattern('+-').optional() & pattern('0-9') & char('.') & pattern('0-9').plus());

  Parser int_() =>
      (pattern('+-').optional() & pattern('1-9') & pattern('0-9').plus()) |
      (pattern('+-').optional() & pattern('0-9'));

  // Bool literal
  Parser boolean() =>
      ref0(boolTrue) |
      ref0(boolFalse);

  Parser boolTrue() =>
      string('true') & ref0(notIdentifier).and();
  
  Parser boolFalse() =>
      string('false') & ref0(notIdentifier).and();

  // Null literal
  Parser null_() =>
      string('null') & ref0(notIdentifier).and();
  
  // Object literal
  Parser objBase(Object value) {
    if (value is Parser) {
      return char('{').skip(after: ref0(whitespace).star()) &
          (ref0(name) & char(':').skip(before: ref0(whitespace).star(), after: ref0(whitespace).plus()) & value)
          .starSeparated(ref0(objSeparator)) &
          char('}').skip(before: ref0(objSeparator));
    }
    throw ArgumentError.value(value, 'Invalid parser');
  }

  Parser objSeparator() => ref1(_trim, anyOf(',;')) | ref0(whitespace).star();

  Parser obj() =>
      ref1(objBase, ref0(expr));

  // Array literal
  Parser arrBase(Object value) {
    if (value is Parser) {
      return char('[').skip(after: ref0(whitespace).star()) &
        (value.skip(after: ref0(whitespace).star()) & ref1(_trim, ',').optional()).star() &
        char(']').skip(before: ref0(whitespace).star());
    }
    throw ArgumentError.value(value, 'Invalid parser');
  }

  Parser arr() =>
      ref1(arrBase, ref0(expr));
  
  // Function base syntax
  Parser fnBase() =>
      char('(').skip(after: ref0(whitespace).star()) & ref0(params) & ref1(_trim, ')') &
      ref0(varType).optional() & ref1(_trim, '{') & ref0(statements) & char('}').skip(before: ref0(whitespace).star());

  // Define function statement
  Parser fnDef() =>
      char('@') & ref0(name) & ref0(fnBase);
  
  // Function expression
  Parser fn() =>
      char('@') & ref0(fnBase);

  Parser param() =>
      ref0(name) & ref0(varType).optional();
  
  Parser params() =>
      ref0(param).starSeparated(ref0(separator));
  
  // Static array literal
  Parser staticArr() =>
      ref1(arrBase, ref0(staticLiteral));

  // Static object literal
  Parser staticObj() =>
      ref1(objBase, ref0(staticLiteral));
  
  // Type
  Parser type() =>
      ref0(fnType) |
      ref0(namedType);
  
  Parser fnType() =>
      ref1(_trim, '@(') & ref0(argTypes) & ref1(_trim, ')') & ref1(_trim, '=>') & ref0(type);
  
  Parser argTypes() =>
      ref0(type).starSeparated(ref0(separator));
  
  Parser namedType() =>
      ref0(name) &
      (char('<').trim(ref0(spaceOnly)) & ref0(type) & char('>').skip(before: ref0(spaceOnly).star())).optional();
}

// Preprocessor
class AiScriptPreprocessGrammarDefinition extends AiScriptGrammarDefinition {
  @override
  Parser start() => ref0(preprocessPart).star().end();

  Parser preprocessPart() =>
      ref0(tmpl) |
      ref0(str) |
      ref0(comment) |
      any();
  
  Parser comment() =>
      string('//') & newline().neg().starString() |
      string('/*') & string('*/').neg().starString() & string('*/');

}