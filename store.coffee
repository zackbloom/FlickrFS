_ = require('underscore')
fs = require('fs')
debug = require('debug')('FFS:Store')
PngEncoder = require('png').Png
PngDecoder = require('png-js')

Client = require('./client')

class FlickrStore
  HEADER_SIZE: 8

  constructor: (client, @opts={}) ->
    @client = new Client client, @opts
  
  addHeader: (buffer, imageSize) ->
    # The header is just a 64 bit unsigned int representing the size of the
    # original file.
    out = new Buffer(imageSize)
    out.writeUInt32BE(buffer.length >> 32, 0)
    out.writeUInt32BE(buffer.length & 0xFFFFFFFF, 4)
    buffer.copy(out, @HEADER_SIZE)
    
    out

  readHeader: (buffer) ->
    high = buffer.readUInt32BE(0)
    low = buffer.readUInt32BE(4)
    size = high << 32 | low

    out = buffer.slice(@HEADER_SIZE)

    return [out, size]

  write: (path, buffer, mode='644', cb) ->
    size = Math.ceil(Math.sqrt((buffer.length + @HEADER_SIZE) / 3))

    byteSize = size * size * 3
    dataSize = buffer.length

    debug 'adding header'
    buffer = @addHeader(buffer, byteSize)

    debug 'encoding'
    png = new PngEncoder(buffer, size, size, 'rgb')
  
    opts =
      tags: ["size:#{ dataSize }", "mode:#{ mode }"]

    debug 'writing'
    @client.writePhoto(path, png.encodeSync(), opts, cb)

  stripAlphas: (data) ->
    debug 'stripping'
    out = new Buffer(Math.ceil(data.length*3/4))

    sourcei = desti = 0
    n = 1
    while sourcei < data.length
      if 4*n - 1 == sourcei
        n++
      else
        out[desti++] = data[sourcei]

      sourcei++

    debug 'done'
    out

  read: (id, cb) ->
    debug 'read photo'
    @client.readPhoto id, (err, stream) =>
      chunks = []
      stream.on 'data', (chunk) ->
        chunks.push chunk

      stream.on 'end', =>
        buffer = Buffer.concat(chunks)
        debug 'decoding'
        img = new PngDecoder(buffer)

        debug 'calling decode'
        img.decode (pixels) =>
          debug 'stripping alphas'
          pixels = @stripAlphas pixels
          debug 'done. reading header'

          [data, size] = @readHeader pixels
  
          debug 'slicing data'
          data = data.slice(0, size)

          debug 'done slicing'
          cb null, data

module.exports = FlickrStore
