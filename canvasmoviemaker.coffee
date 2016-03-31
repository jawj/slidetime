
class CanvasMovieMaker

  constructor: (@canvas, @context) ->
    @listeners = {}

    @worker = new Worker 'canvasmovieworker.js'  # + '?' + Math.random()
    @worker.addEventListener 'message', (event) =>  
      # type (data): stdin (str), stdout (str), frame (frame #), done (Uint8Array), error (?)
      message = event.data
      @trigger message.type, message.data

  setSource: (@canvas, @context) ->
    @reset()
    @frameCount = 0

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

  addFrame: ->
    imageName = "frame_#{@frameCount++}.pam"
    canvasData = @context.getImageData(0, 0, @canvas.width, @canvas.height).data
    imageData = new Uint8Array(@imageHeader.byteLength + canvasData.byteLength)
    imageData.set @imageHeader
    imageData.set canvasData, @imageHeader.byteLength
    @addFile imageName, imageData.buffer
    @

  addFile: (fileName, fileBuffer, transfer = yes) ->
    try
      @worker.postMessage {type: 'file', name: fileName, data: fileBuffer}, if transfer then [fileBuffer]
    catch e  # for IE
      @worker.postMessage {type: 'file', name: fileName, data: fileBuffer}
    @

  encode: (inArgs, otherArgs, memory = 512 * 1024 * 1024, transferBack = yes) ->  
    # memory: 768MB is around max Chrome allows (and gives 'Aw, snap!' half the time)
    args = "-f image2 -c:v pam #{inArgs} -i frame_%d.pam #{otherArgs} -y output.bin"
    argsArr = args.match(/\S+/g)
    @worker.postMessage 
      type: 'command'
      arguments: argsArr
      memory: memory
      transferBack: transferBack
    @

  reset: ->
    @worker.postMessage type: 'reset'
    @

