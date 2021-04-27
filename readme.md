# niml

Niml is domain specific language that translates to string of valid html. Templates can be created easily to support modularity. You can define ui components as procs that take parameters. Package is still in early stage.

# example

## input

```nim
let ten = 10
let text = "text"

echo niml:
  html:
    head:
      meta charset & "UTF-8"
      meta `http-equiv` & "X-UA-Compatible", content & "IE=edge"
      meta name & "viewport", content&"width=device-width, initial-scale=1.0"
      title "Niml"
    body:
      h1 "Headline"
      p:
        "some text"
        br
        "some more text"
        table:
          tr:
            td @text
            td @ten
          tr:
            td "something else"
            td "30"
        divider attribute & @text, another_attribute & @(ten + 30 - 16):
          "this is actually div but as that is already taken keyword we are using alternative"
```

## output

```html
<html>
  <head>
    <meta charset="UTF-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Niml</title>
  </head>
  <body>
    <h1>Headline</h1>
    <p>
      some text
      <br/>
      some more text
    </p>
    <table>
      <tr>
        <td>text</td>
        <td>10</td>
      </tr>
      <tr>
        <td>something else</td>
        <td>30</td>
      </tr>
    </table>
    <div attribute="text" another_attribute="24">
      this is actually div but as that is already taken keyword we are using alternative
    </div>
  </body>
</html>
```

Output will look like this only if you use `--define:debug` flag, otherwise it will be all on one line. As you can see all statements prefixed with `@` get evaluated as expected. Advantage is that you can embed one html string to another and utilize modular design. All that from nim code.

# performance

Using this dls can only slow down compile time, runtime should be same as if you hardcoded strings and appended some variable parts to them.

# flexibility

The names of your elements are only limited by nim keywords. In comparison to htmlgen you don't have to use nested prentices as everything is expressed by indentation witch improves readability. Niml is over all shorter then html and faster to write and modify.

## example of modularity

```nim
proc popup(id, callback, message: string, hidden = false): string = 
  niml:
    divider id & @id, style & "too lazy for this", hidden & @hidden:
      h1 @message
      button id & @(id & "-yes"), onclick & @callback:
        "Yes"
      button onclick & "close-popup", popup_id & @id:
        "No"

let pg = niml:
  @(popup("exit-popup", "exit", "Do you want to exit?", true))
  @(popup("open-exit-popup", "open-exit", "Do you want to open exit-popup?"))

echo pg
```
(syntax for calling proc may improve in a future)

## output

```html
<div id="exit-popup" style="too lazy for this" hidden="true">
  <h1>Do you want to exit?</h1>
  <button id="exit-popup-yes" onclick="exit">
    Yes
  </button>
  <button onclick="close-popup" popup_id="exit-popup">
    No
  </button>
</div>

<div id="open-exit-popup" style="too lazy for this" hidden="false">
  <h1>Do you want to open exit-popup?</h1>
  <button id="open-exit-popup-yes" onclick="open-exit">
    Yes
  </button>
  <button onclick="close-popup" popup_id="open-exit-popup">
    No
  </button>
</div>
```