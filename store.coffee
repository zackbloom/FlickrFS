_ = require('underscore')

class FlickrStore
  constructor: (@client, @opts={}) ->
  
  makeRequest: (method, params, cb) ->
    @client.createRequest(method, params, true, cb).send()

  writePhoto: (path, dataStream, opts={}, cb) ->
    params =
      title: path
      is_public: 0
      is_friend: 0
      is_family: 0
      hidden: 2
      photo: dataStream

    tags = ['fs']
    if opts.tags?
      tags.push.apply(params.tags, opts.tags)
    params.tags = tags.join(' ')

    _.extend params, opts.params

    @makeRequest 'upload', params, cb

  writePhotoTags: (id, tags, cb) ->
    if _.isArray(tags)
      tags = tags.join(' ')

    params =
      photo_id: id
      tags: tags

    @makeRequest 'flickr.photos.setTags', params, cb

  readPhotoInfoByPath: (path, cb) ->
    params =
      user_id: 'me'
      text: path

    @makeRequest 'flickr.photos.search', params, (err, resp) ->
      return cb(err) if err?

      photos = resp.photos.photo

      if photos.length == 0
        cb {'code': 'ENOENT'}
      else if photos.length > 1
        console.warn "Multiple files found matching name #{ path }"

      cb null, photos[0]

  readPhotoInfoById: (id, cb) ->
    params =
      photo_id: id

    @makeRequest 'flickr.photos.getInfo', params, (err, resp) ->
      if err?
        if err.message.indexOf('not found') isnt -1
          err.code = 'ENOENT'
        return cb(err)

      cb(null, resp)

module.exports = FlickrStore
