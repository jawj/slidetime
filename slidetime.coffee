
class TimerMaker

  soundOptions:
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

  encSettingsOptions:
    mpeg1:
      videocodec:  '-c:v mpeg1video -q:v 4'
      audiocodec:  '-c:a mp2 -b:a 64k'
      format:      '-f mpeg'
      inframerate: 1
      framerate:   25
      audiolag:    -1
      ext:         'mpg'
    mp4:
      videocodec:  '-c:v mpeg4 -q:v 1'  # q:v 1 - 31 => best - worst
      audiocodec:  '-c:a aac -q:a 6'    # q:a 0 - 9  => best - worst
      format:      '-f mp4'
      inframerate: 1
      framerate:   1
      audiolag:    0
      ext:         'mp4'
    avi:
      videocodec:  '-c:v mpeg4 -q:v 1'  # q:v 1 - 31 => best - worst
      audiocodec:  ' -c:a aac -q:a 6'   # q:a 0 - 9  => best - worst
      format:      '-f avi'
      inframerate: 1
      framerate:   1
      audiolag:    1
      ext:         'avi'
      
  # --- begin defaults ---

  timerSeconds: 10800
  warnSeconds:  10

  fontSize:     60
  fontStyle:    'bold'
  fontFace:     'Myriad Pro'

  colors:
    main:
      fg: '#000000'
      bg: '#ffffff'
    warn:
      fg: '#000000'
      bg: '#ffff00'
    last:
      fg: '#ffff00'
      bg: '#000000'

  encSettings: @::encSettingsOptions.mp4
  sound: @::soundOptions.ding

  # --- end defaults ---

  zeroPad: (s, len) ->
    s += ''
    s = '0' + s while s.length < len
    s

  formatTime: (seconds, maxSeconds, output = '') -> 
    h = Math.floor(seconds / 3600)
    m = Math.floor(seconds % 3600 / 60)
    s = seconds % 60

    maxH = Math.floor(maxSeconds / 3600)
    maxM = Math.floor(maxSeconds % 3600 / 60)
    maxS = maxSeconds % 60

    output += @zeroPad(h, (maxH + '').length) + ':' if maxH > 0
    output += @zeroPad(m, (if maxH is 0 and maxM < 10 then 1 else 2)) + ':'
    output += @zeroPad(s, 2)
    
    output

  prepareCanvas: ->
    font = "#{@fontStyle} #{@fontSize}px #{@fontFace}"

    zeroCanvas = document.createElement 'canvas'
    zeroCtx = zeroCanvas.getContext '2d'
    zeroCtx.font = font
    textWidth = zeroCtx.measureText(@formatTime 0, @timerSeconds).width
    @textHeight = @fontSize * 0.86
    @padding = @textHeight * 0.12

    canvasWidth = @textHeight + textWidth + @padding * 4
    canvasWidth += 16 - (canvasWidth % 16) if canvasWidth % 16 > 0  # round width up to a multiple of 16
    
    canvasHeight = @textHeight + @padding * 2
    canvasHeight += 16 - (canvasHeight % 16) if canvasHeight % 16 > 0  # round height up to a multiple of 16 too

    if @canvas
      @canvas.width  = canvasWidth
      @canvas.height = canvasHeight
    else
      @canvas = make 
        tag: 'canvas'
        width: canvasWidth
        height: canvasHeight

    @ctx = @canvas.getContext '2d'
    @ctx.font = font

    @

  drawClock: (i) ->
    colType = if i is 0 then 'last' else if i <= @warnSeconds then 'warn' else 'main'
    bgCol = @colors[colType].bg
    fgCol = @colors[colType].fg

    clockOuterRadius = @textHeight * 0.5
    clockInnerRadius = clockOuterRadius * 0.9
    clockCenter = clockOuterRadius + @padding
    
    # clear
    @ctx.fillStyle = bgCol
    @ctx.fillRect 0, 0, @canvas.width, @canvas.height
    
    # text
    @ctx.fillStyle = fgCol
    @ctx.fillText @formatTime(i, @timerSeconds), @textHeight + @padding * 3, @textHeight * 0.93 + @padding

    # clock face
    @ctx.fillStyle = fgCol
    @ctx.beginPath()
    @ctx.arc clockCenter, clockCenter, clockOuterRadius, 0, 2 * Math.PI, yes
    @ctx.fill()

    # clock segment
    @ctx.strokeStyle = bgCol
    @ctx.lineWidth = clockInnerRadius
    @ctx.beginPath()
    startAngle = if i is 0 then 0 else 2 * Math.PI * (1 - i / @timerSeconds) - 0.5 * Math.PI
    endAngle = if i is 0 then Math.PI * 2 else Math.PI * 1.49999  # 1.5 fails to draw all round
    @ctx.arc clockCenter, clockCenter, clockInnerRadius * 0.5, startAngle, endAngle, yes
    @ctx.stroke()

    @

  makeMovie: (soundData) ->
    @prepareCanvas()

    @mm.setSource @canvas, @ctx, @encSettings, soundData, @timerSeconds
    # @mm.addFile @sound.file, soundData.buffer if @sound

    i = @timerSeconds
    iTarget = if @sound then -@sound.length else 0

    callback = =>
      if i >= iTarget
        if i >= 0 then @drawClock i
        i -= 1
        @mm.addFrame callback

      else
        @mm.encode()

    callback()
    @

  start: ->
    if @sound
      xhr url: @sound.file, type: 'arraybuffer', success: (req) =>
        soundData = req.response
        @makeMovie soundData
    else
      @makeMovie()

  constructor: ->
    @mm = new CanvasMovieMaker()

    @mm.on 'starting', (args) -> console.log "starting with arguments: #{args.join ' '}"
    @mm.on 'stderr', (data) -> console.log data
    @mm.on 'frame', (frame) =>
      completionMsg = "#{Math.floor(frame / (@mm.frameCount * @encSettings.framerate) * 100)}% completed" 
      (get id: 'completed').innerHTML = completionMsg
      console.log completionMsg
    
    @mm.on 'done', (buffer) =>
      return unless buffer?
      
      filename = "slidetime.#{@encSettings.ext}"
      # Safari's createObjectURL is still completely broken in 9.1
      videoURL = if navigator.vendor is 'Apple Computer, Inc.' then 'data:video/mp4;base64,' + b64 new Uint8Array buffer  
      else URL.createObjectURL new Blob [buffer]

      link = make tag: 'a', download: filename, text: 'Download', href: videoURL, parent: (get tag: 'body'), onclick: ->
        if navigator.msSaveOrOpenBlob?
          navigator.msSaveOrOpenBlob (new Blob [buffer]), filename
          return no


body = (get tag: 'body')
sampleText = '16:03'

fontChooser = FontChooser sampleText, 250, [], (font) ->
  for sample in (get cls: 'fc-sample', inside: fontSizeChooser.dropdown) 
    sample.style.fontFamily = font
    redrawPreview()

body.appendChild fontChooser.input

fontSizeChooser = FontSizeChooser sampleText, null, null, (size) ->
  redrawPreview()

body.appendChild fontSizeChooser.input

tm = new TimerMaker()

redrawPreview = ->
  tm.fontFace = fontChooser.input.value
  tm.fontSize = 0 + fontSizeChooser.input.value

  tm.prepareCanvas()
  tm.drawClock tm.timerSeconds

  parent = get id: 'sampleCanvasParent'
  oldCanvas = parent.lastChild
  if oldCanvas? then parent.removeChild oldCanvas 
  parent.appendChild tm.canvas


make 
  tag: 'button'
  text: 'Render movie'
  parent: body
  onclick: -> 
    tm.start()


