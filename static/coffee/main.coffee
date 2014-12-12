
data = []
duration = 0
maxRps = 0
baseTime = 0

graph_redraw = ->
  scale = [{time:0, value:0},{time:duration, value:maxRps}]
  data_graphic
    data: [data, scale]
    area: false
    width: 600
    height: 350
    target: '#graph'
    x_accessor: 'time'
    y_accessor: 'value'
    interpolate: 'monotone'
    transition_on_update: false


getConfig = (c) ->
  duration = c.duration
  maxRps = c.maxRps


updateGraph = (d) ->
  if not baseTime
    baseTime = d.time
  data.push
    time: d.time - baseTime
    value: d.value
  do graph_redraw


orangeClick = (form) ->
  # FIXME: check URL & normalize it
  d3.select('#msg').text('Prepare for the worst...')
  spin = spinner
    width: 350
    height: 350
    container: '#spinner'

  req = JSON.stringify(url: form.elements[0].value)
  d3.json('/bang').post req, (err, rsp) ->
    if not rsp.error
      wsURL = "ws://#{location.hostname}:#{rsp.ws_port}/#{rsp.job}"
      ws = new WebSocket wsURL
      ws.onmessage = (m) ->
        d = JSON.parse m.data
        if d.config # server wants to share some config options
          getConfig d.config

        if d.stop
          d3.select('#msg').text(
            if d.stop.error then d.stop.error else 'Finished successfully')

        if d.key == 'overall.RPS'
          d3.select('#msg').text('Test in progress...')
          spin.stop()
          updateGraph d
  false
