import 
  unittest,
  niml

test "all syntax types":
  # identifier by it self will be translated into empty tag
  let s1 = niml: divider
  
  check s1 == """

<div></div>"""
  
  # identifier with string after it will get translated into
  # tag with text content
  let s2 = niml: divider "content"

  check s2 == """

<div>content</div>"""

  # identifier with infix expression is translated into empty 
  # tag with attribute
  let s3 = niml: divider key & "value"

  check s3 == """

<div key="value"></div>"""

  # as in html value can be omitted
  let s4 = niml: divider key

  check s4 == """

<div key></div>"""

  # using quoted expression allows you to use special characters
  # witch is often needed
  let s5 = niml: divider `ugly-key` & "value"

  check s5 == """

<div ugly-key="value"></div>"""

  # multiple attributes are allowed and if you specify string at the
  # end, it will be considered body of tag
  let s6 = niml: divider key & "value", hidden, lang & "en", "content"

  check s6 == """

<div key="value" hidden lang="en">content</div>"""

  # if you want to nest tags you can use code block and when we are at it
  # lets show that you can add a doctype tag like follows, this only works 
  # for this exact identifier and only if it is no the beginning
  let s7 = niml:
    doctype_html
    html:
      head:
        title "hello"
      body:
        "hello"
  
  check s7 == """
<!doctype html>
<html>
  <head>
    <title>hello</title>
  </head>
  <body>
    hello
  </body>
</html>"""

test "templates":
  let 
    variable = "variable"
    number = 10

  # values from scope can be embedded inside niml at almost any place
  # you can also nest an expression that evaluates to something on witch
  # we can apply '$' operator
  let s1 = niml:
    divider value & @variable:
      @variable
      p @variable
      @(variable & " and something")
      @number

  
  check s1 == """

<div value="variable">
  variable
  <p>variable</p>
  variable and something
  10
</div>"""

test "readme":
  let e1 = niml:
    doctype_html
    html:
      head lang & "en":
        head:
          meta charset & "UTF-8"
          meta `http-equiv` & "X-UA-Compatible", content & "IE=edge"
          meta name & "viewport", content & "width=device-width, initial-scale=1.0"
          title "Document"
        body:
          h1 "Hello world!"
  
  check e1 == """
<!doctype html>
<html>
  <head lang="en">
    <head>
      <meta charset="UTF-8"></meta>
      <meta http-equiv="X-UA-Compatible" content="IE=edge"></meta>
      <meta name="viewport" content="width=device-width, initial-scale=1.0"></meta>
      <title>Document</title>
    </head>
    <body>
      <h1>Hello world!</h1>
    </body>
  </head>
</html>"""

  proc popup(id, callback, message: string, hidden = false): string = 
    niml:
      divider id & @id, style & "too lazy for this", hidden & @hidden:
        h1 @message
        button id & @(id & "-yes"), onclick & @(callback & "()"):
          "Yes"
        button onclick & "close_popup()", popup_id & @id:
          "No"

  let e2 = niml:
    @popup "exit-popup", "exit", "Do you want to exit?", true
    @popup "open-exit-popup", "open_exit", "Do you want to open exit-popup?"

  check e2 == """


<div id="exit-popup" style="too lazy for this" hidden="true">
  <h1>Do you want to exit?</h1>
  <button id="exit-popup-yes" onclick="exit()">
    Yes
  </button>
  <button onclick="close_popup()" popup_id="exit-popup">
    No
  </button>
</div>

<div id="open-exit-popup" style="too lazy for this" hidden="false">
  <h1>Do you want to open exit-popup?</h1>
  <button id="open-exit-popup-yes" onclick="open_exit()">
    Yes
  </button>
  <button onclick="close_popup()" popup_id="open-exit-popup">
    No
  </button>
</div>"""
      
