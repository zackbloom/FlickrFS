_ = require('underscore')
http = require('http')
crypto = require('crypto')
debug = require('debug')('FFS:PhotoClient')

class FlickrPhotoClient
  constructor: (@client, @opts={}) ->
  
  makeRequest: (method, params, cb) ->
    @client.createRequest(method, params, true, cb).send()

  writePhoto: (path, dataStream, opts={}, cb) ->
    if _.isFunction opts
      cb = opts
      opts = {}

    params =
      title: @encodeTitle path
      is_public: 0
      is_friend: 0
      is_family: 0
      hidden: 2
      photo: dataStream

    tags = ['fs']
    if opts.tags?
      tags.push.apply(tags, opts.tags)
    debug tags
    params.tags = tags.join(' ')

    _.extend params, opts.params

    debug 'uploading'
    @makeRequest 'upload', params, (err, resp) ->
      debug 'done'
      cb(err, resp?.photoid)

  readPhoto: (id, cb) ->
    debug 'getting sizes'
    @readSizes id, (err, sizes) =>
      return cb(err) if err?

      debug 'read sizes'
      url = @getOriginalURL sizes
      @readURL url, cb

  readURL: (url, cb) ->
    debug 'getting'
    http.get url, (stream) ->
      debug 'got'
      cb null, stream

  getOriginalURL: (sizes) ->
    for size in sizes
      if size.label is 'Original'
        return size.source

    throw "Original photo cannot be found in response."

  writePhotoTags: (id, tags, cb) ->
    if _.isArray(tags)
      tags = tags.join(' ')

    params =
      photo_id: id
      tags: tags

    @makeRequest 'flickr.photos.setTags', params, cb

  encodeTitle: (path) ->
    if @opts.encodePath
      crypto.createHash('sha1').update(path).digest('hex')
    else
      path

  readSizes: (id, cb) ->
    params =
      photo_id: id

    @makeRequest 'flickr.photos.getSizes', params, (err, resp) ->
      return cb(err) if err?

      cb(null, resp.sizes.size)

  readPhotoInfo: (id, cb) ->
    params =
      photo_id: id

    @makeRequest 'flickr.photos.getInfo', params, (err, resp) ->
      if err?
        if err.message?.indexOf('not found') isnt -1
          err.code = 'ENOENT'
        return cb(err)

      for key, val of resp.photo
        if val?._content
          resp.photo[key] = val._content

      cb(null, resp.photo)

module.exports = FlickrPhotoClient
