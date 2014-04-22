
body = (get tag: 'body')
sampleText = '16:03'

fontChooser = FontChooser sampleText, 250, [], (font) ->
  for sample in (get cls: 'fc-sample', inside: fontSizeChooser.dropdown) 
    sample.style.fontFamily = font

body.appendChild fontChooser.input

fontSizeChooser = FontSizeChooser sampleText
body.appendChild fontSizeChooser.input

make 
  tag: 'button'
  text: 'Render movie'
  parent: body
  onclick: -> drawClock(15)


timerSeconds = 60
warnSeconds = 10

fontSize = 60
fontStyle = 'bold'
fontFace = 'Myriad Pro'

colors =
  main:
    bg: '#0080ff'
    fg: '#ffffff'
  warn:
    bg: '#0080ff'
    fg: '#ffff00'
  last:
    bg: '#ffff00'
    fg: '#000000'

sounds =
  gong:
    file:   'gong.wav'
    length: 6
  ding:
    file:   'chime.wav'
    length: 3
  echo:
    file:   'echo.wav'
    length: 3
  alarm:
    file:   'alarm.wav'
    length: 3

allEncSettings =
  mpeg1:
    codecs:     '-c:v mpeg1video -q:v 4 -c:a mp2 -b:a 64k -f mpeg'
    framerate:  25
    audiolag:   -1
    ext:        'mpg'
  mp4:
    codecs:     '-c:v mpeg4 -q:v 1 -c:a aac -strict -2 -q:a 6 -f mp4'  # q:v 1 - 31 =>  best - worst, q:a 0 - 9 => best - worst
    framerate:  1
    audiolag:   0
    ext:        'mp4'
  avi:
    codecs:     '-c:v mpeg4 -q:v 1 -c:a aac -strict -2 -q:a 6 -f avi'  # q:v 1 - 31 =>  best - worst, q:a 0 - 9 => best - worst
    framerate:  1
    audiolag:   1
    ext:        'avi'
    
settings = allEncSettings.mp4
sound = sounds.ding



font = "#{fontStyle} #{fontSize}px #{fontFace}"

ffargs = ''
ffargs += "
  -f wav
  -itsoffset #{timerSeconds + settings.audiolag}
  -async 1
  -i #{sound.file} " if sound
ffargs += "
  -r #{settings.framerate} #{settings.codecs} "

zeroPad = (s, len) ->
  s += ''
  s = '0' + s while s.length < len
  s

formatTime = (seconds, maxSeconds, output = '') -> 
  h = Math.floor(seconds / 3600)
  m = Math.floor(seconds % 3600 / 60)
  s = seconds % 60

  maxH = Math.floor(maxSeconds / 3600)
  maxM = Math.floor(maxSeconds % 3600 / 60)
  maxS = maxSeconds % 60

  output += zeroPad(h, (maxH + '').length) + ':' if maxH > 0
  output += zeroPad(m, (if maxH is 0 and maxM < 10 then 1 else 2)) + ':'
  output += zeroPad(s, 2)
  
  output

zeroCanvas = document.createElement 'canvas'
zeroCtx = zeroCanvas.getContext '2d'
zeroCtx.font = font
textWidth = zeroCtx.measureText(formatTime 0, timerSeconds).width
textHeight = fontSize * 0.86
padding = textHeight * 0.12

canvasWidth = textHeight + textWidth + padding * 4
canvasWidth += 4 - (canvasWidth % 4) if canvasWidth % 4 > 0  # round width up to a multiple of 4
canvasHeight = textHeight + padding * 2

canvas = make 
  tag: 'canvas'
  width: canvasWidth
  height: canvasHeight
  parent: (get tag: 'body')

ctx = canvas.getContext '2d'
ctx.font = font

clockOuterRadius = textHeight * 0.5
clockInnerRadius = clockOuterRadius * 0.9
clockCenter = clockOuterRadius + padding


mm = new CanvasMovieMaker canvas, ctx

mm.on 'starting', (args) -> console.log "starting with arguments: #{args.join ' '}"
mm.on 'stderr', (data) -> console.log data
mm.on 'frame', (frame) -> console.log "completed: #{Math.floor(frame / (mm.frameCount * settings.framerate) * 100)}%"
mm.on 'done', (buffer) ->
  return unless buffer?
  videoBlob = new Blob [buffer]
  videoURL = URL.createObjectURL videoBlob
  link = make tag: 'a', download: "slidetime.#{settings.ext}", text: 'Download', href: videoURL, parent: (get tag: 'body')

drawClock = (i) ->
  colType = if i is 0 then 'last' else if i <= warnSeconds then 'warn' else 'main'
  bgCol = colors[colType].bg
  fgCol = colors[colType].fg
  
  # clear
  ctx.fillStyle = bgCol
  ctx.fillRect 0, 0, canvas.width, canvas.height
  
  # text
  ctx.fillStyle = fgCol
  ctx.fillText formatTime(i, timerSeconds), textHeight + padding * 3, textHeight * 0.93 + padding

  # clock face
  ctx.fillStyle = fgCol
  ctx.beginPath()
  ctx.arc clockCenter, clockCenter, clockOuterRadius, 0, 2 * Math.PI, yes
  ctx.fill()

  # clock segment
  ctx.strokeStyle = bgCol
  ctx.lineWidth = clockInnerRadius
  ctx.beginPath()
  startAngle = if i is 0 then 0 else 2 * Math.PI * (1 - i / timerSeconds) - 0.5 * Math.PI
  endAngle = if i is 0 then Math.PI * 2 else Math.PI * 1.49999  # 1.5 fails to draw all round
  ctx.arc clockCenter, clockCenter, clockInnerRadius * 0.5, startAngle, endAngle, yes
  ctx.stroke()

main = (soundData) ->
  mm.addFile sound.file, soundData.buffer if sound

  for i in [timerSeconds..0]
    drawClock i
    mm.addFrame()

  mm.addFrame() for j in [1..sound.length] if sound
  mm.encode '-r 1', ffargs
    
if sound
  xhr url: sound.file, type: 'arraybuffer', success: (req) ->
    soundData = new Uint8Array req.response
    main soundData
else
  main()

