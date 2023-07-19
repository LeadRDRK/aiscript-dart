import 'package:petitparser/petitparser.dart';

import 'grammar.dart';
import 'cst.dart';

import '../core/node.dart';
import '../core/ast.dart';

class AiScriptParserDefinition extends AiScriptGrammarDefinition {
  @override
  Parser block() => super.block().token().map((token) =>
    BlockNode(
      statements: token.value[1],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser bracket(String brackets, Parser parser) => super.bracket(brackets, parser).map((value) => value[1]);

  @override
  Parser statementsBase(Object input) => super.statementsBase(input).map((value) => value.elements.cast<Node>());

  @override
  Parser namespace() => super.namespace().token().map((token) =>
    NamespaceNode(
      name: token.value[1],
      members: token.value[3] ?? [],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser meta() => super.meta().token().map((token) =>
    token.value[1]..loc = Loc.fromToken(token)
  );

  @override
  Parser metaWithName() => super.metaWithName().map((value) =>
    MetaNode(
      name: value[0],
      value: value[1]
    )
  );

  @override
  Parser metaWithoutName() => super.metaWithoutName().map((value) =>
    MetaNode(value: value)
  );

  @override
  Parser varDef() => super.varDef().token().map((token) =>
    DefinitionNode(
      name: token.value[1],
      varType: token.value[2],
      expr: token.value[4],
      mut: token.value[0] == 'var',
      attr: [],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser varType() => super.varType().map((value) => value[1]);

  @override
  Parser out() => super.out().token().map((token) =>
    CallNode(
      target: IdentifierNode(
        name: 'print',
        loc: Loc(token.start, token.start + 1)
      ),
      args: [token.value[1]],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser attr() => super.attr().token().map((token) =>
    AttributeNode(
      name: token.value[1],
      value: token.value[2] ?? BoolNode(value: true),
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser letDeclaration() => super.letDeclaration().map((value) => value[1]);

  @override
  Parser each() => super.each().token().map((token) =>
    token.value[1]..loc = Loc.fromToken(token)
  );

  @override
  Parser eachWithParens() => super.eachWithParens().map((value) =>
    EachNode(
      varName: value[1],
      items: value[3],
      body: value[5]
    )
  );

  @override
  Parser eachWithoutParens() => super.eachWithoutParens().map((value) =>
    EachNode(
      varName: value[0],
      items: value[2],
      body: value[3]
    )
  );

  @override
  Parser for_() => super.for_().token().map((token) =>
    token.value[1]..loc = Loc.fromToken(token)
  );

  @override
  Parser forWithParens() => super.forWithParens().map((value) => value[1]);

  @override
  Parser forVarWithParens() => super.forVarWithParens().map((value) =>
    ForNode(
      varName: value[0],
      from: value[1]?[1] ?? NumNode(value: 0),
      to: value[3],
      body: value[5]
    )
  );

  @override
  Parser forTimesWithParens() => super.forTimesWithParens().map((value) =>
    ForNode(
      times: value[0],
      body: value[2]
    )
  );

  @override
  Parser forVarWithoutParens() => super.forVarWithoutParens().map((value) =>
    ForNode(
      varName: value[0],
      from: value[1]?[1] ?? NumNode(value: 0),
      to: value[3],
      body: value[4]
    )
  );

  @override
  Parser forTimesWithoutParens() => super.forTimesWithoutParens().map((value) =>
    ForNode(
      times: value[0],
      body: value[1]
    )
  );

  @override
  Parser return_() => super.return_().token().map((token) =>
    ReturnNode(
      expr: token.value[1],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser loop() => super.loop().token().map((token) =>
    LoopNode(
      statements: token.value[2],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser break_() => super.break_().token().map((token) =>
    BreakNode(loc: Loc.fromToken(token))
  );

  @override
  Parser continue_() => super.continue_().token().map((token) =>
    ContinueNode(loc: Loc.fromToken(token))
  );

  @override
  Parser assignOrExpr() => super.assignOrExpr().token().map((token) {
    final dest = token.value[0];
    final assign = token.value[1];
    if (assign == null) {
      return dest; // Expr
    }
    
    final op = assign[0];
    final expr = assign[1];
    final loc = Loc.fromToken(token);

    if (op == '+=') {
      return AddAssignNode(dest: dest, expr: expr, loc: loc);
    }
    else if (op == '-=') {
      return SubAssignNode(dest: dest, expr: expr, loc: loc);
    }
    else {
      return AssignNode(dest: dest, expr: expr, loc: loc);
    }
  });

  @override
  Parser infixOrExpr2() => super.infixOrExpr2().token().map((token) {
    if (token.value[1].isEmpty) {
      return token.value[0]; // Expr2
    }

    final Node head = token.value[0];
    final List<dynamic> tails = token.value[1];

    final operands = [head, ...tails.map((e) => e[1] as Node)];
    final operators = tails.map((e) => e[0] as String).toList();

    return InfixNode(
      operands: operands,
      operators: operators,
      loc: Loc.fromToken(token)
    );
  });

  @override
  Parser op() => super.op().flatten();

  @override
  Parser not() => super.not().token().map((token) => 
    NotNode(
      expr: token.value[1],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser chainOrExpr3() => super.chainOrExpr3().token().map((token) =>
    token.value[1].isNotEmpty ?
    ChainedNode(
      parent: token.value[0],
      chain: token.value[1].cast<Node>(),
      loc: Loc.fromToken(token)
    ) :
    token.value[0] // Expr3
  );

  @override
  Parser callChain() => super.callChain().token().map((token) =>
    CallChainNode(
      args: token.value[1],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser callArgs() => super.callArgs().map((value) => value.elements.cast<Node>());

  @override
  Parser indexChain() => super.indexChain().token().map((token) =>
    IndexChainNode(
      index: token.value[1],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser propChain() => super.propChain().token().map((token) =>
    PropChainNode(
      name: token.value[1],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser if_() => super.if_().token().map((token) =>
    IfNode(
      cond: token.value[1],
      then: token.value[2],
      elseifBlocks: token.value[3] ?? [],
      elseBlock: token.value[4],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser elseifBlocks() => super.elseifBlocks().map((value) => value.elements.cast<ElseifBlock>());

  @override
  Parser elseifBlock() => super.elseifBlock().map((value) =>
    ElseifBlock(value[1], value[2])
  );

  @override
  Parser elseBlock() => super.elseBlock().map((value) => value[1]);

  @override
  Parser match() => super.match().token().map((token) =>
    MatchNode(
      about: token.value[1],
      qs: (token.value[3] as List).cast<MatchCase>(),
      defaultRes: token.value[4],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser matchCase() => super.matchCase().map((value) =>
    MatchCase(value[0], value[2])
  );

  @override
  Parser matchDefaultCase() => super.matchDefaultCase().map((value) => value[2]);

  @override
  Parser eval() => super.eval().token().map((token) =>
    BlockNode(
      statements: token.value[2],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser identifier() => super.identifier().token().map((token) =>
    IdentifierNode(
      name: token.value,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser tmpl() => super.tmpl().token().map((token) =>
    TmplNode(
      tmpl: _concatTemplate(token.value),
      loc: Loc.fromToken(token)
    )
  );

  dynamic _escChar(dynamic esc) => (esc as String)[1];

  @override
  Parser tmplEsc() => super.tmplEsc().map(_escChar);

  @override
  Parser tmplExpr() => super.tmplExpr().map((value) => value[1].cast<Node>());
  
  @override
  Parser str() => super.str().token().map((token) =>
    StrNode(
      value: token.value.join(),
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser strDoubleQuoteEsc() => super.strDoubleQuoteEsc().map(_escChar);

  @override
  Parser strSingleQuoteEsc() => super.strSingleQuoteEsc().map(_escChar);

  @override
  Parser num_() => super.num_().token().map((token) =>
    NumNode(
      value: token.value,
      loc: Loc.fromToken(token)
    )
  );

  @override 
  Parser float() => super.float().flatten().map(double.parse);

  @override 
  Parser int_() => super.int_().flatten().map(int.parse);

  @override
  Parser boolean() => super.boolean().token().map((token) =>
    BoolNode(
      value: token.value[0] == 'true',
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser null_() => super.null_().token().map((token) =>
    NullNode(loc: Loc.fromToken(token))
  );

  @override
  Parser objBase(Object value) => super.objBase(value).map((value) =>
    { for (var v in value[1].elements) v[0]: v[2] }
  );

  @override
  Parser obj() => super.obj().token().map((token) =>
    ObjNode(
      value: token.value.cast<String, Node>(),
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser arrBase(Object value) => super.arrBase(value).map((value) =>
    value[1].map((v) => v[0]).toList().cast<Node>()
  );

  @override
  Parser arr() => super.arr().token().map((token) =>
    ArrNode(
      value: token.value,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser fnBase() => super.fnBase().token().map((token) =>
    FnNode(
      params: token.value[1],
      retType: token.value[3],
      children: token.value[5]
    )
  );

  @override
  Parser fnDef() => super.fnDef().token().map((token) =>
    DefinitionNode(
      name: token.value[1],
      expr: token.value[2]..loc = Loc.fromToken(token),
      mut: false,
      attr: [],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser fn() => super.fn().token().map((token) =>
    token.value[1]..loc = Loc.fromToken(token)
  );

  @override
  Parser param() => super.param().map((value) =>
    FnParam(value[0], value[1])
  );

  @override
  Parser params() => super.params().map((value) => value.elements.cast<FnParam>());

  @override
  Parser staticArr() => super.staticArr().token().map((token) =>
    ArrNode(
      value: token.value,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser staticObj() => super.staticObj().token().map((token) =>
    ObjNode(
      value: token.value.cast<String, Node>(),
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser fnType() => super.fnType().token().map((token) =>
    FnTypeSourceNode(
      args: token.value[1].cast<Node>(),
      result: token.value[4],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser argTypes() => super.argTypes().map((value) => value.elements);

  @override
  Parser namedType() => super.namedType().token().map((token) =>
    NamedTypeSourceNode(
      name: token.value[0],
      inner: token.value[1]?[1],
      loc: Loc.fromToken(token)
    )
  );
}

List<dynamic> _concatTemplate(List<dynamic> arr) {
  List<List<String>> looseStrs = [];
  bool gotStr = false;
  arr.retainWhere((e) {
    if (e is String) {
      if (gotStr) {
        looseStrs.last.add(e);
        return false;
      }

      looseStrs.add([]);
      gotStr = true;
    }
    else if (gotStr) {
      gotStr = false;
    }

    return true;
  });

  int i = 0;
  List<dynamic> res = [];
  for (final e in arr) {
    if (e is String) {
      res.add(e + looseStrs[i++].join());
    }
    else {
      res.addAll(e);
    }
  }
  return res;
}

class AiScriptPreprocessParserDefinition extends AiScriptPreprocessGrammarDefinition {
  @override
  Parser start() => super.start().map((value) => value.join());

  @override
  Parser tmpl() => super.tmpl().flatten();

  @override
  Parser str() => super.str().flatten();

  @override
  Parser comment() => super.comment().map((_) => '');
}