
# get latest ffmpeg
# comment out arc4random in libavutil/random_seed.c

cd ffmpeg
mkdir dist


make clean  # if run before

DEBUG=1

if [ $DEBUG -eq 1 ]; then
  CONFOPTFLAGS='-O1'
  EMCCOPTFLAGS='-O1 -g'
else
  CONFOPTFLAGS='-O3'
  EMCCOPTFLAGS='-O3 --closure 1'
fi

emconfigure ./configure --cc="emcc" --prefix=./dist \
  --enable-cross-compile --target-os=none --arch=x86_32 --cpu=generic --optflags=$CONFOPTFLAGS \
  --disable-ffplay --disable-ffprobe --disable-ffserver --disable-asm --disable-doc --disable-devices --disable-pthreads \
  --disable-w32threads --disable-network --disable-hwaccels --disable-parsers --disable-bsfs --disable-debug --disable-zlib \
  --disable-protocols --disable-indevs --disable-outdevs \
  --enable-protocol=file --enable-pic --enable-small \
  --disable-demuxers --enable-demuxer='image2,wav,concat,mpeg1system,mp4,mov,avi' \
  --disable-decoders --enable-decoder='pam,pcm_s16le' \
  --disable-encoders --enable-encoder='mpeg1video,h263,mp2,aac,mpeg4' \
  --disable-filters --enable-filter='adelay,apad,aperms,aresample,aselect,asendcmd,asetnsamples,format,perms,scale,select,sendcmd,amovie,movie,ffbuffersink,ffabuffersink,abuffer,buffer,abuffersink,buffersink,afifo,fifo' \
  --disable-muxers --enable-muxer='mpeg1system,mp4,avi'

emmake make
make install
mv dist/bin/ffmpeg ffmpeg.bc

emcc $EMCCOPTFLAGS ffmpeg.bc -o ../slidetime/ffmpeg-20160403.js --pre-js ../slidetime/ffmpeg_pre.js --post-js ../slidetime/ffmpeg_post.js

exit

###

old ffmpeg_pre.js
=================

this['ffmpeg_run'] = function(opts, callback) {
  var Module = {
    'outputDirectory': 'output'
  };
  for (var i in opts) Module[i] = opts[i];
  var outputFilePath = Module['arguments'][Module['arguments'].length - 1];
  if (Module['arguments'].length > 2 && outputFilePath && outputFilePath.indexOf(".") > -1) {
    Module['arguments'][Module['arguments'].length - 1] = "output/" + outputFilePath;
  }
  Module['preRun'] = [function() {
    FS.init(opts['stdin'], opts['stdout'], opts['stderr']);
    FS.createFolder('/', Module['outputDirectory'], true, true);
    Module['files'].forEach(function(file) {
      FS.createDataFile('/', file.name, file.data, true, true);
    });
  }];
  Module['postRun'] = [function() {
    var result = FS.analyzePath(Module['outputDirectory']);
    var buffers = [];
    if (result && result.object && result.object.contents) {
      for (var i in result.object.contents) {
        if (result.object.contents.hasOwnProperty(i)) {

          buffers.push({
            name: i,
            data: new Uint8Array(result.object.contents[i].contents).buffer
          });
        }
      }
    }
    callback(buffers);
  }];


old ffmpeg_post.js
==================

}
