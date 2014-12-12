#
# adapted from http://bl.ocks.org/Mattwoelk/6132258
#

arc = (svg, rInner, rOuter, duration, direction) ->
  a = d3.svg.arc()
    .innerRadius(rInner)
    .outerRadius(rOuter)
    .startAngle(0)

  x = if direction == 'clockwise' then [0,360] else [360,0]
  x = x.map((alpha) -> "rotate(#{alpha})")
  timer = null
  stop  = false

  spin  = (selection) ->
    selection.transition()
      .ease('linear')
      .duration(duration)
      .attrTween('transform', -> d3.interpolateString(x[0], x[1]))

    if not stop
      timer = setTimeout((-> spin selection), duration)

  svg.append('path')
     .datum(endAngle: 0.66*Math.PI)
     .style('opacity', 0.2)
     .attr('d', a)
     .call(spin)

  stop: ->
    stop = true # prevent new timer from starting
    clearTimeout(timer) # stop pending timer


spinner = (config) ->
  r = Math.min(config.width, config.height) / 2
  duration = 1500

  svg = d3.select(config.container)
    .append('svg')
      .attr('width', config.width)
      .attr('height', config.height)
      .append('g')
        .attr('transform', "translate(#{config.width/2},#{config.height/2})")

  arc1 = arc(svg, r*0.5, r*0.9, duration, 'clockwise')
  arc2 = arc(svg, r*0.1, r*0.4, duration, 'ccw')
  d3.select(config.container).style('display', 'block')

  stop: ->
    d3.select(config.container).style('display', 'none')
    arc1.stop()
    arc2.stop()
