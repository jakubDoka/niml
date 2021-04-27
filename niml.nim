import niml/html
export html

proc defaultPage*(title, body: string, styles = ""): string =
  ## defaultPage creates a standard html page with custom title,
  ## styles and body
  let p = page:
    html lang & "en":
      head:
        meta charset & "UTF-8"
        meta `http-equiv` & "X-UA-Compatible", content & "IE=edge"
        meta name & "viewport", content&"width=device-width, initial-scale=1.0"
        title exp(title)
        style: 
          exp(styles)
      body:
        exp(body)

  when defined(debug):
    return "<!DOCTYPE html>\n" & p
  else:
    return "<!DOCTYPE html>" & p

when isMainModule:
  let body = page:
    h1 "Good morning"
    p:
      "How are you today?"
      br
      "Its so interesting any yet so complicated."
  
  echo defaultPage("something", body)
  