
printStdout = (text) -> postMessage type: 'stdout', data: text
printStderr = (text) -> postMessage type: 'stderr', data: text

stdErrStr = ''
stderrCallback = (chr) ->
  stdErrStr += String.fromCharCode chr unless chr is null
  frame = stdErrStr.match /frame=\s*(\d+)[^\d]$/
  postMessage type: 'frame', data: +frame[1] if frame
  if chr is 10 or chr is null
    printStderr stdErrStr.trimRight()
    stdErrStr = ''

files = null  # scope

reset = ->
  files = []

reset()

@onmessage = (event) ->
  type = event.data.type

  if type is 'reset'
    reset()

  else if type is 'file'
    newFile = name: event.data.name, data: new Uint8Array event.data.data
    files.push newFile

  else if type is 'command'
    importScripts 'ffmpeg-custom.js' unless this.ffmpeg_run  # import on first command

    opts =
      arguments: event.data.arguments
      TOTAL_MEMORY: event.data.memory  # 512MB is probably around the safe limit for Chrome
      files: files
      print: printStdout
      stderr: stderrCallback

    postMessage type: 'starting', data: opts.arguments
    result = ffmpeg_run opts
    movieBuffer = result?[0]?.data
    postMessage type: 'done', data: movieBuffer, if movieBuffer and event.data.transferBack then [movieBuffer]
