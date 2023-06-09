this['ffmpeg_run'] = (opts, callback) ->
  args = opts['arguments']
  Module = {
    "arguments":    args
    "TOTAL_MEMORY": opts['memory']
  }
  Module['preRun'] = [->
    FS.init opts['stdin'], opts['stdout'], opts['stderr']
    while file = opts['files'].pop()
      FS.writeFile file.name, file.data, encoding: 'binary'
    null
  ]
  Module['postRun'] = [->
    outputFilePath = args.pop()
    outputFile = FS.readFile outputFilePath, encoding: 'binary'
    callback outputFile
    null
  ]

  ### delete this line and _everything_ below ###
  null
