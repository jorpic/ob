
data = []

graph_redraw = ->
  data_graphic
    title: 'quantiles.100'
    description: 'test results'
    data: data
    width: 400
    height: 250
    target: '#graph'
    x_accessor: 'time'
    y_accessor: 'value'
    interpolate: 'monotone'
    transition_on_update: false


orangeClick = (form) ->
  req = JSON.stringify(url: form.elements[0].value)
  d3.json('/bang').post req, (err, rsp) ->
    if not rsp.error
      wsURL = "ws://#{location.hostname}:#{rsp.ws_port}/#{rsp.job}"
      ws = new WebSocket wsURL
      ws.onopen = ->
      ws.onmessage = (m) ->
        d = JSON.parse m.data
        if d.key == 'cumulative.quantiles.100_0'
          data.push
            time: new Date(d.time)
            value: d.value
          if data.length > 1
            do graph_redraw
            console.debug d
      ws.onclose = ->
  false
