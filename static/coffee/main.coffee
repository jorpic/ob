
orangeClick = ->
  inp = document.getElementById 'url'
  req = JSON.stringify(url: inp.value)
  d3.json('/bang').post req, (err, rsp) ->
    wsURL = "ws://#{location.hostname}:#{rsp.ws_port}/#{rsp.job}"
    ws = new WebSocket wsURL
    ws.onopen = ->
    ws.onmessage = (m) -> console.debug m
    ws.onclose = ->
