_ = require('underscore')
fs = require('fs')
debug = require('debug')('FFS:Store')
PngEncoder = require('png').Png
PngDecoder = require('png-js')
Path = require('path')

Client = require('./client')

now = -> Math.floor((new Date) / 1000)

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

  useDirectoryTree: (cb) ->
    @readDirectoryTree (err, files) =>
      if err?.code is 'ENOENT'
        # This is the initial setup, the directory tree
        # doesn't exist yet.
        cb(null, {
          '/': _.extend @defaultInfo('/'),
            type: 'directory'
        })
      else if err
        cb(err)
      else
        cb(null, files)

  readDirectoryTree: (cb) ->
    if not @opts.directoryPhotoId
      console.log "No directory photo id"
      return cb({code: 'ENOENT'})

    @readData @opts.directoryPhotoId, (err, data) ->
      return cb(err) if err

      rows = data.split('\n')
      version = rows[0]

      files = []
      for row in rows[1..]
        file = JSON.parse row
        files[file.path] = file

      cb(null, files)

  writeDirectoryTree: (files, cb) ->
    version = '0'

    rows = [version]
    for path, info of files
      info.path = @normalizePath(path)
      rows.push JSON.stringify info

    buffer = new Buffer(rows.join('\n'))

    @writeData '__DIR__', buffer, (err, id) =>
      @opts.directoryPhotoId = id
      console.log "DIRECTORY ID: #{ id }"

  info: (path, cb) ->
    @useDirectoryTree (err, tree) =>
      info = tree?[@normalizePath(path)]

      debug 'INFO', info, tree, @normalizePath(path)
      cb(err, info)
  
  defaultInfo: (path) ->
    return {
      path: path
      mode: '644'
      owner: 'root'
      group: 'root'
      ctime: now()
      atime: now()
      mtime: now()
    }

  normalizePath: (path) ->
    path = Path.normalize path
    path = path.replace(/\/$/, '')

    if path is ''
      path = '/'

    path

  list: (loc, cb) ->
    loc = @normalizePath(loc)

    @useDirectoryTree (err, tree) ->
      if not tree[loc]
        return cb({code: 'ENOENT'})

      if tree[loc].type isnt 'directory'
        return cb({code: 'EINVAL'})

      list = []
      re = new RegExp("#{ loc }/[^/]+")
      for path, info of tree
        if re.test(path)
          list.push info

      cb(null, list)

  writeDirectory: (path, info) ->
    path = @normalizePath(path)

    _.extend info, @defaultInfo(path),
      type: 'directory'

    @useDirectoryTree (err, tree) =>
      return cb(err) if err

      tree[path] = info

      @writeDirectoryTree tree, cb

  writeFile: (path, buffer, info={}, cb) ->
    if _.isFunction(info)
      cb = info
      info = {}

    size = buffer.length

    path = @normalizePath(path)

    _.extend info, @defaultInfo(path),
      type: 'file'
      blocks: []
      size: size
      
    @useDirectoryTree (err, tree) =>
      return cb(err) if err

      @writeData path, buffer, (err, id, diskSize) ->
        return cb(err) if err

        info.blocks.push {
          diskSize,
          size,
          id,
          start: 0,
          end: size
        }

        tree[path] = info
  
        @writeDirectoryTree tree, cb
     
  writeData: (path, buffer, cb) ->
    size = Math.ceil(Math.sqrt((buffer.length + @HEADER_SIZE) / 3))

    byteSize = size * size * 3
    dataSize = buffer.length

    debug 'adding header'
    buffer = @addHeader(buffer, byteSize)

    debug 'encoding'
    png = new PngEncoder(buffer, size, size, 'rgb')
  
    opts =
      tags: ["size:#{ dataSize }"]

    debug 'writing photo'
    @client.writePhoto path, png.encodeSync(), opts, (err, id) ->
      cb(err, id, byteSize)

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

  readData: (id, cb) ->
    debug 'read photo'
    @client.readPhoto id, (err, stream) =>
      return cb(err) if err

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
