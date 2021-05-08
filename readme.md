# niml

Niml is domain specific language that translates to string of valid html. Templates can be created easily to support modularity. You can define ui components as procs that take parameters.

# changelog

## 0.2.0
- compilation performance improved
- macro output is cleaner
- component syntax improved
- specifying attributes without value is now valid
- specifying attributes and content in one line is now valid with no need of opening scope
- errors now displays its position
- special syntax for doctype tag

# example

## input

```nim
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
```

## output

```html
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
</html>
```

Output will look like this only if you use `--define:debug` flag, otherwise it will be all on one line.

# performance

Using this dls can only slow down compile time, runtime should be same as if you hardcoded strings and appended some variable parts to them.

# flexibility

The names of your elements are only limited by nim keywords. In comparison to htmlgen you don't have to use nested prentices as everything is expressed by indentation witch improves readability. Niml is over all shorter then html and faster to write and modify. Bets feature though is ability to nest values from the scope. This is comparable to what react can do if not the same.

## example of modularity

### input
```nim
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
```

### output

```html
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
</div>
```