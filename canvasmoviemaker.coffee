
class CanvasMovieMaker

  bytesPerClip: 50e6

  constructor: (@canvas, @context) ->
    @listeners = {}

    @worker = new Worker 'canvasmovieworker.js' + '?' + Math.random()
    @worker.addEventListener 'message', (event) =>  
      # type (data): stdin (str), stdout (str), frame (frame #), done (Uint8Array), error (?)
      message = event.data
      if message.type is 'clip'
        @clips.push message.data
        @files = []
        @callback()
      else if message.type is 'lastClip'
        @clips.push message.data
        @files = []
        @encode2()
      else
        @trigger message.type, message.data
  
  #  make: (@opts) ->  # context, nextFrameFunc, settings

  setSource: (@canvas, @context, @encSettings, @soundData, @timerSeconds) ->
    @files = []
    @clips = []
    @frameCount = 0
    @clipFrameCount = 0
    @clipFrameBytes = 0

    imageHeaderStr = "P7\nWIDTH #{@canvas.width}\nHEIGHT #{@canvas.height}\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n"
    @imageHeader = new Uint8Array imageHeaderStr.length
    @imageHeader[i] = imageHeaderStr.charCodeAt(i) for i in [0...imageHeaderStr.length]

  addEventListener: (eventName, callbackFunc) -> 
    @listeners[eventName] ?= []
    @listeners[eventName].push callbackFunc
    @

  on: @::addEventListener

  trigger: (eventName, arg) ->
    func(arg) for func in (@listeners[eventName] || [])
    @

  addFrame: (@callback) ->
    imageName = "frame_#{@clipFrameCount}.pam"
    canvasData = @context.getImageData(0, 0, @canvas.width, @canvas.height).data
    imageData = new Uint8Array(@imageHeader.byteLength + canvasData.byteLength)
    imageData.set @imageHeader
    imageData.set canvasData, @imageHeader.byteLength
    @addFile imageName, imageData.buffer

    @frameCount++
    @clipFrameCount++    
    @clipFrameBytes += imageData.byteLength

    if @clipFrameBytes > @bytesPerClip
      @clipFrameCount = 0
      @clipFrameBytes = 0
      @encodeClip()

    else
      @callback()

    @

  addFile: (fileName, fileBuffer) ->
    @files.push name: fileName, data: fileBuffer
    @

  encodeClip: (returnType = 'clip') ->  
    console.log "encoding up to frame #{@frameCount}"
    # memory: 768MB is around max Chrome allows (and gives 'Aw, snap!' half the time)
    args = "-f image2 -c:v pam -r #{@encSettings.inframerate} -i frame_%d.pam -r #{@encSettings.framerate} #{@encSettings.videocodec} #{@encSettings.format} -y output.bin"
    @worker.postMessage 
      type: 'command'
      returnType: returnType
      arguments: args.match /\S+/g
      files: @files
      memory: 64 * 1024 * 1024
    , (file.data for file in @files)  # objects to transfer
    @

  encode: () ->
    if @clipFrameCount > 0
      @encodeClip 'lastClip'
    else
      @encode2()

  encode2: ->
    list = ''
    for clip, i in @clips
      fileName = "clip_#{i}.bin"
      @addFile fileName, clip
      list += "file '#{fileName}'\n"

    listArray = new Uint8Array list.length
    listArray[i] = list.charCodeAt(i) for i in [0...list.length]
    @addFile 'list.txt', listArray.buffer

    if @soundData
      console.log 'sound'
      @addFile 'sound.wav', @soundData

    args = "-f concat -i list.txt "
    if @soundData then args += "-f wav -itsoffset #{@timerSeconds + @encSettings.audiolag} -i sound.wav "
    args += "-c:v copy #{@encSettings.audiocodec} #{@encSettings.format} -y output.bin"

    @worker.postMessage 
      type: 'command'
      returnType: 'done'
      arguments: args.match /\S+/g
      files: @files
      memory: 128 * 1024 * 1024
    , (file.data for file in @files)  # objects to transfer
    @

