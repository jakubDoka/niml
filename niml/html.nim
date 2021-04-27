import macros, fusion/matching, strutils
    
proc toString(n: NimNode): string {.compileTime.} = 
    if n.kind == nnkAccQuoted:
        for i in n:
            result.add(i.strVal)
    else:
        result.add(n.strVal)

template debug(s: string): untyped =
    when defined(debug):
        buff.add(s)
    
template merge(str: string, exp: NimNode): untyped =
    let lit = newStringLit(str)
    result = quote do:
        `result` & `lit` & `exp`

proc expand(n: NimNode, depth: int = 0): NimNode {.compileTime.} =
    let space = "  ".repeat(max(depth, 0))
    if n.matches(Call[==ident("exp"), @body]):
        if depth == -1 or not defined(debug):
            return body
        return quote do:
            `space` & `body` & "\n"
    
    if n.matches(Ident()):
        when defined(debug):
            return newLit(space & "<" & n.strVal & "/>\n")
        else:
            return newLit("<" & n.strVal & "/>")
    
    let nodeOk = n.matches:
        Command[@name is Ident(), .._] | Call[@name is Ident(), _]

    if not nodeOk:
        if n.matches(StrLit() | TripleStrLit()):
            when defined(debug):
                return newLit(space & n.strVal & "\n")
            else:
                return n
        else:
            error("invalid syntax")

    result = newLit("")

    var buff = ""

    debug space

    buff.add("<" & name.strVal)

    if n.matches(Command[_, @value is StrLit()]):
        buff.add(">" & value.strVal & "</" & name.strVal & ">")
        debug "\n"
        return newLit(buff)
    elif n.matches(Command[_, Call[==ident("exp"), @body]]):
        buff.add(">")
        let lit = newLit(buff)
        result = quote do:
            `result` & `lit` & `body`
        buff = "</" & name.strVal & ">"
        debug "\n"
        let lit2 = newLit(buff)
        result = quote do:
            `result` & `lit2`
        return
    elif n.matches(Command[_, until @args is StmtList(), .._]):
        for arg in args:
            let argOK = arg.matches:
                        Infix[==ident("&"), @key, @value]
            if not argOK:
                error(
                    "element attribute has to be in form ˙key & \"value\"˙, key can optionally " & 
                    "be inside ``, value can be an expression that evaluates to string"
                )
            buff.add(" " & key.toString & "=")
            if value.matches(StrLit()):
                buff.add(value.repr)
            else:
                let lit = newLit(buff)
                let value = expand(value, -1)
                result = quote do:
                    `result` & `lit` & "\"" & `value` & "\""
                buff = ""

    var last = n[n.len-1]
    if last.matches(StmtList()):
        buff.add(">")
        debug "\n"
        let lit = newLit(buff)
        result = quote do:
            `result` & `lit`
        buff = ""
        for n in last:
            let exp = expand(n, depth + 1)
            result = quote do:
                `result` & `exp`
        debug space
        buff.add("</" & name.strVal & ">")
    else:
        buff.add("/>")
    debug "\n"
    
    let lit = newLit(buff)
    result = quote do:
        `result` & `lit`
        
macro page*(code: untyped): untyped =
    ## page takes input in form of syntax tree and turns it into string expression
    ## witch can also contain dynamic parts, for example:
    ##
    ## .. code-block:: nim
    ##   let
    ##     a = "hello"
    ##     b = 10
    ##     pg = page: 
    ##       html attribute&"value", otherAttribute&exp($b), `ugly-attribute`&"brah":
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
    ## If you need to specify ugly identifier write it as operator. If you enclose 
    ## something into exp() you can use variables from scope inside, though expression
    ## has to evaluate into string. You can use --define:debug to view a formatted html
    result = newLit("")

    for n in code:
        let exp = expand(n)
        result = quote do:
            `result` & `exp`

when isMainModule:
    let brah = "hello there"
    let val = 10
    let pg = page:
        html lang & "en", kub & "flee":
            head:
                meta charset & "UTF-8"
                meta `http-equiv` & "X-UA-Compatible", content & "IE=edge"
                meta name & "viewport", content&"width=device-width, initial-scale=1.0"
                title "Fonting"
            body:
                h1 "Hello there"
                p hello & exp(brah)
                p exp(brah)
                p:
                    exp(brah)
                    br
                    exp($(3 + 5 + val))
    assert pg == """<html lang="en" kub="flee">
  <head>
    <meta charset="UTF-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Fonting</title>
  </head>
  <body>
    <h1>Hello there</h1>
    <p hello="hello there"/>
    <p>hello there</p>
    <p>
      hello there
      <br/>
      18
    </p>
  </body>
</html>
"""

