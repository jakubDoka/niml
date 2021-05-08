import macros, strutils
    
type
  NodeKind = enum
    nkString
    nkNode
  Node = object
    case kind: NodeKind
    of nkString:
      str: string
    of nkNode:
      node: NimNode
  Pointer = tuple
    node: NimNode
    index: int

template toNimNode(n: Node): NimNode =
  case n.kind:
  of nkString:
    newLit(n.str)
  else:
    newTree(nnkPrefix, ident("$"), n.node)

template ifDebug(code, eCode: untyped): untyped =
  when defined(debug):
    code
  else:
    eCode

template front(tag: string): untyped =
  "<" & tag & ">"

template ending(tag: string): untyped =
  "</" & tag & ">"

template str(s: string): Node =
  Node(kind: nkString, str: s)

template node(n: NimNode): Node =
  if n[0].strVal != "@":
    err("external values can be prefixed only with '@'", n)
  Node(kind: nkNode, node: n[1])

template err(message: string, node: NimNode) =
  error(node.lineInfo & ": " & message)

template ind(amount: int): string = "  ".repeat(amount)

template translate(val: string): string =
  case val:
  of "divider":
    "div"
  else:
    val

proc insert(construct: var seq[Node], value: Node, p: Pointer, offset: var int) =
  construct.insert value, p.index + offset
  offset.inc

proc expand(code: NimNode): NimNode =
  var
    frontier, temp: seq[Pointer]
    construct: seq[Node]
    level: int
    buffer: string
  
  for n in code: 
    frontier.add((n, 0))

  while frontier.len != 0:
    var offset: int
    
    ifDebug:
      let
        nl = "\n"
        id = ind(level)
        ni = nl & id
    do:
      let id, nl, ni = ""
        
    for node in frontier.mitems:
      case node.node.kind:
      of nnkIdent:
        let val = translate node.node.strVal
        construct.insert str(ni & front(val) & ending(val)), node, offset

      of nnkStrLit, nnkTripleStrLit:
        construct.insert str(ni & node.node.strVal), node, offset
      
      of nnkCommand, nnkCall, nnkPrefix:
        if (node.node.kind == nnkCall or node.node.kind == nnkCommand) and node.node[0].kind == nnkPrefix:
          node.node[0] = node.node[0][1]
          node.node = newTree(nnkPrefix, ident("@"), node.node)
        
        if node.node.kind == nnkPrefix:
          construct.insert str(ni), node, offset
          construct.insert node(node.node), node, offset
        else:
          let val = translate node.node[0].strVal
          construct.insert str(ni & "<" & val), node, offset
          
          var i = 1
          while i < node.node.len:
            let n = node.node[i]
            case n.kind:
            of nnkInfix:
              let     
                op = n[0]
                id = n[1]
                vl = n[2]
      
              if op.strVal != "&":
                err("only '&' infix is allowed in attribute definition", n[0])
              
              var identifier: string
              case id.kind:
              of nnkIdent:
                identifier = id.strVal
              of nnkAccQuoted:
                for n in id:
                  identifier.add n.strVal
              else:
                err("operand of a right side has to be identifier or quoted inside ``", id)

              case vl.kind:
              of nnkStrLit, nnkTripleStrLit:
                construct.insert str(" $#=\"$#\"" % [identifier, vl.strVal]), node, offset
              of nnkPrefix:
                construct.insert str(" $#=\"" % identifier), node, offset
                construct.insert node(vl), node, offset
                construct.insert str("\""), node, offset
              else:
                err("value of attribute can be string or prefixed variable from outer scope", vl)
            of nnkIdent:
              construct.insert str(" " & n.strVal), node, offset
            of nnkAccQuoted:
              var identifier: string
              for n in n:
                identifier.add n.strVal
              construct.insert str(" " & identifier), node, offset
            else:
              break
            
            i.inc
        
          construct.insert str(">"), node, offset
          
          var single = true
          if i == node.node.len - 1:
            let n = node.node[i]
            case n.kind:
            of nnkStrLit, nnkTripleStrLit:
              construct.insert str(n.strVal), node, offset
            of nnkStmtList:
              single = false
              for n in n:
                temp.add (n, node.index + offset)
            of nnkPrefix:
              construct.insert node(n), node, offset
            else:
              err("invalid kind of final value, only string literal or statement list is allowed", n)
          elif i < node.node.len - 1:
            err("each tag can have only one final value, everything else has to be attribute", node.node)

          if single:
            construct.insert str(ending(val)), node, offset
          else:
            construct.insert str(ni & ending(val)), node, offset
      else:
        err("invalid syntax", node.node)
    swap(frontier, temp)
    temp.setLen(0)
    level.inc

  var 
    i: int
  
  for j in 1..<construct.len:
    let c = construct[j]
    var t = construct[i].addr
    if t.kind == c.kind and t.kind == nkString:
      t.str.add c.str
    else:
      i.inc
      construct[i] = c
    
  construct.setLen(i + 1)
    
  result = construct[0].toNimNode()
  
  for i in 1..<construct.len:
    result = newTree(nnkInfix, ident("&"), result, construct[i].toNimNode())
        
macro niml*(code: untyped): untyped =
    ## niml takes input in form of syntax tree and turns it into string expression
    ## witch can also contain dynamic parts, for example:
    ##
    ## .. code-block:: nim
    ##   let
    ##     a = "hello"
    ##     b = 10
    ##     pg = niml: 
    ##       html attribute&"value", otherAttribute&@b, `ugly-attribute`&"brah":
    ##         head:
    ##           title exp(a)
    ##         body:
    ##           h1 exp(a)
    ##           p exp("b = " & $b)
    ##           p "this is same as"
    ##           p:
    ##             "this"
    ##
    ## When defining attributes you have to use & instead of = for technical reasons.
    ## If you need to specify ugly identifier write it as operator. If you prefix
    ## something with @ to refer to it, though expression has to evaluate into string 
    ## of have $ defined. You can use --define:debug to view a formatted html.
    if code[0] == ident("doctype_html"):
      code.del(0)
      result = newTree(nnkInfix, ident("&"), newLit("<!doctype html>"), expand(code))
    else:
      result = expand(code)