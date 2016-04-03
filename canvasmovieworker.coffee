
importScripts 'ffmpeg-20160403.js' + '?' + Math.random()

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

@onmessage = (event) ->
  opts =
    arguments: event.data.arguments
    memory: event.data.memory  # 512MB is probably around the safe limit for Chrome
    files: event.data.files
    print: printStdout
    stderr: stderrCallback

  postMessage type: 'starting', data: opts.arguments
  ffmpeg_run opts, (result) ->
    movieBuffer = result.buffer
    try
      postMessage type: event.data.returnType, data: movieBuffer, [movieBuffer]
    catch  # for IE
      postMessage type: event.data.returnType, data: movieBuffer
