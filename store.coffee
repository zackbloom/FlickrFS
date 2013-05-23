_ = require('underscore')
fs = require('fs')
resumer = require('resumer')
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

  write: (path, buffer, cb) ->
    size = Math.ceil(Math.sqrt((buffer.length + @HEADER_SIZE) / 3))

    byteSize = size * size * 3

    buffer = @addHeader(buffer, byteSize)

    png = new PngEncoder(buffer, size, size, 'rgb')
  
    @client.writePhoto(path, png.encodeSync(), cb)

  stripAlphas: (data) ->
    out = new Buffer(data.length)

    sourcei = desti = 0
    n = 1
    while sourcei < data.length
      if 4*n - 1 == sourcei
        n++
      else
        out[desti++] = data[sourcei]

      sourcei++

    out

  read: (id, cb) ->
    @client.readPhoto id, (err, stream) =>
      data = ''
      stream.on 'data', (chunk) ->
        data += chunk.toString('hex')

      stream.on 'end', =>
        buffer = new Buffer(data, 'hex')

        img = new PngDecoder(buffer)

        img.decode (pixels) =>
          pixels = @stripAlphas pixels

          [data, size] = @readHeader pixels
  
          data = data.slice(0, size)

          cb null, data

module.exports = FlickrStore
