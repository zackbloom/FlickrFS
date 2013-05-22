f4js = require('fuse4js')
{Flickr} = require('flickr-with-uploads')
FlickrStore = require('./store.coffee')

class FlickrFS
  constructor: (@store, @opts={}) ->

  getattr: (path, cb) ->

start = (opts) ->
  client = new Flickr(opts.API_KEY, opts.API_SECRET, opts.ACCESS_TOKEN, opts.ACCESS_SECRET)
  store = new FlickrStore(client, opts)
  handlers = new FlickrFS(store, opts)

  store.readPhotoInfo '5', ->
    console.log arguments
  #f4js.start opts.mount, handlers, True
  #
module.exports = {FlickrFS, start}
