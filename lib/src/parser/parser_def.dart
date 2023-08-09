import 'package:petitparser/petitparser.dart';

import 'grammar.dart';
import 'cst.dart';

import '../core/node.dart';
import '../core/ast.dart';

class AiScriptParserDefinition extends AiScriptGrammarDefinition {
  @override
  Parser block() => super.block().token().map((token) =>
    BlockNode(
      statements: token.value[1] as List<Node>,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser bracket(String brackets, Parser parser) =>
      super.bracket(brackets, parser).map((value) => value[1]);

  @override
  Parser statementsBase(Object input) =>
    super.statementsBase(input).map((value) => (value.elements as List).cast<Node>());

  @override
  Parser namespace() => super.namespace().token().map((token) =>
    NamespaceNode(
      name: token.value[1] as String,
      members: (token.value[3] ?? []) as List<Node>,
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
      name: value[0] as String,
      value: value[1] as Node
    )
  );

  @override
  Parser metaWithoutName() => super.metaWithoutName().map((value) =>
    MetaNode(value: value as Node)
  );

  @override
  Parser varDef() => super.varDef().token().map((token) =>
    DefinitionNode(
      name: token.value[1] as String,
      varType: token.value[2] as Node?,
      expr: token.value[4] as Node,
      mut: (token.value[0] as String) == 'var',
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
      args: [token.value[1] as Node],
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser attr() => super.attr().token().map((token) =>
    AttributeNode(
      name: token.value[1] as String,
      value: (token.value[2] ?? BoolNode(value: true)) as Node,
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
      varName: value[1] as String,
      items: value[3] as Node,
      body: value[5] as Node
    )
  );

  @override
  Parser eachWithoutParens() => super.eachWithoutParens().map((value) =>
    EachNode(
      varName: value[0] as String,
      items: value[2] as Node,
      body: value[3] as Node
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
      varName: value[0] as String,
      from: (value[1]?[1] ?? NumNode(value: 0)) as Node,
      to: value[3] as Node,
      body: value[5] as Node
    )
  );

  @override
  Parser forTimesWithParens() => super.forTimesWithParens().map((value) =>
    ForNode(
      times: value[0] as Node,
      body: value[2] as Node
    )
  );

  @override
  Parser forVarWithoutParens() => super.forVarWithoutParens().map((value) =>
    ForNode(
      varName: value[0] as String,
      from: (value[1]?[1] ?? NumNode(value: 0)) as Node,
      to: value[3] as Node,
      body: value[4] as Node
    )
  );

  @override
  Parser forTimesWithoutParens() => super.forTimesWithoutParens().map((value) =>
    ForNode(
      times: value[0] as Node,
      body: value[1] as Node
    )
  );

  @override
  Parser return_() => super.return_().token().map((token) =>
    ReturnNode(
      expr: token.value[1] as Node,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser loop() => super.loop().token().map((token) =>
    LoopNode(
      statements: token.value[2] as List<Node>,
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
    final dest = token.value[0] as Node;
    final assign = token.value[1] as List<dynamic>?;
    if (assign == null) {
      return dest; // Expr
    }
    
    final op = assign[0] as String;
    final expr = assign[1] as Node;
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
    final head = token.value[0] as Node;
    final tails = token.value[1] as List<dynamic>;

    if (tails.isEmpty) {
      return head; // Expr2
    }

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
      expr: token.value[1] as Node,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser chainOrExpr3() => super.chainOrExpr3().token().map((token) =>
    (token.value[1] as List).isNotEmpty ?
    ChainedNode(
      parent: token.value[0] as Node,
      chain: List.castFrom(token.value[1] as List),
      loc: Loc.fromToken(token)
    ) :
    token.value[0] as Node // Expr3
  );

  @override
  Parser callChain() => super.callChain().token().map((token) =>
    CallChainNode(
      args: token.value[1] as List<Node>,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser callArgs() => super.callArgs().map((value) => (value.elements as List).cast<Node>());

  @override
  Parser indexChain() => super.indexChain().token().map((token) =>
    IndexChainNode(
      index: token.value[1] as Node,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser propChain() => super.propChain().token().map((token) =>
    PropChainNode(
      name: token.value[1] as String,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser if_() => super.if_().token().map((token) =>
    IfNode(
      cond: token.value[1] as Node,
      then: token.value[2] as Node,
      elseifBlocks: List.castFrom(token.value[3] ?? []),
      elseBlock: token.value[4] as Node?,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser elseifBlocks() =>
      super.elseifBlocks().map((value) => (value.elements as List).cast<ElseifBlock>());

  @override
  Parser elseifBlock() => super.elseifBlock().map((value) =>
    ElseifBlock(value[1] as Node, value[2] as Node)
  );

  @override
  Parser elseBlock() => super.elseBlock().map((value) => value[1]);

  @override
  Parser match() => super.match().token().map((token) =>
    MatchNode(
      about: token.value[1] as Node,
      qs: List.castFrom(token.value[3] as List),
      defaultRes: token.value[4] as Node?,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser matchCase() => super.matchCase().map((value) =>
    MatchCase(value[0] as Node, value[2] as Node)
  );

  @override
  Parser matchDefaultCase() => super.matchDefaultCase().map((value) => value[2]);

  @override
  Parser eval() => super.eval().token().map((token) =>
    BlockNode(
      statements: token.value[2] as List<Node>,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser identifier() => super.identifier().token().map((token) =>
    IdentifierNode(
      name: token.value as String,
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
  Parser tmplExpr() => super.tmplExpr().map((value) => (value[1] as List).cast<Node>());
  
  @override
  Parser str() => super.str().token().map((token) =>
    StrNode(
      value: (token.value as List).join(),
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
      value: token.value as num,
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
      value: (token.value[0] as String) == 'true',
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser null_() => super.null_().token().map((token) =>
    NullNode(loc: Loc.fromToken(token))
  );

  @override
  Parser objBase(Object value) => super.objBase(value).map((value) =>
    { for (var v in value[1].elements) v[0] as String: v[2] as Node }
  );

  @override
  Parser obj() => super.obj().token().map((token) =>
    ObjNode(
      value: token.value as Map<String, Node>,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser arrBase(Object value) => super.arrBase(value).map((value) =>
    (value[1] as List).map((v) => v[0]).toList().cast<Node>()
  );

  @override
  Parser arr() => super.arr().token().map((token) =>
    ArrNode(
      value: token.value as List<Node>,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser fnBase() => super.fnBase().token().map((token) =>
    FnNode(
      params: token.value[1] as List<FnParam>,
      retType: token.value[3] as Node?,
      children: token.value[5] as List<Node>
    )
  );

  @override
  Parser fnDef() => super.fnDef().token().map((token) =>
    DefinitionNode(
      name: token.value[1] as String,
      expr: (token.value[2] as Node)..loc = Loc.fromToken(token),
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
    FnParam(value[0] as String, value[1] as Node?)
  );

  @override
  Parser params() =>
      super.params().map((value) => (value.elements as List).cast<FnParam>());

  @override
  Parser staticArr() => super.staticArr().token().map((token) =>
    ArrNode(
      value: token.value as List<Node>,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser staticObj() => super.staticObj().token().map((token) =>
    ObjNode(
      value: token.value as Map<String, Node>,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser fnType() => super.fnType().token().map((token) =>
    FnTypeSourceNode(
      args: List.castFrom(token.value[1] as List),
      result: token.value[4] as Node,
      loc: Loc.fromToken(token)
    )
  );

  @override
  Parser argTypes() => super.argTypes().map((value) => value.elements);

  @override
  Parser namedType() => super.namedType().token().map((token) =>
    NamedTypeSourceNode(
      name: token.value[0] as String,
      inner: token.value[1]?[1] as Node?,
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
  Parser start() => super.start().map((value) => (value as List).join());

  @override
  Parser tmpl() => super.tmpl().flatten();

  @override
  Parser str() => super.str().flatten();

  @override
  Parser comment() => super.comment().map((_) => '');
}