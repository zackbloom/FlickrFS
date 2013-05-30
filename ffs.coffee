Path = require('path')
f4js = require('fuse4js')
_ = require('underscore')
{Flickr} = require('flickr-with-uploads')
FlickrStore = require('./store.coffee')

process.env.DEBUG ?= '*'
debug = require('debug')('FFS:FS')

ERRORS =
  ENOENT: 2   # Not found
  EIO: 5      # IO Error
  EINVAL: 22  # Not a directory

class FlickrFS
  constructor: (@store, @opts={}) ->

  init: (cb) =>
    debug("init")

    do cb

  getattr: (path, cb) =>
    debug("getattr", path)

    code = 0
    stat = {}

    @store.info path, (err, info) ->
      if err?
        code = -ERRORS.EIO

      else if not info
        code = -ERRORS.ENOENT

      else if info.type is 'directory'
        # A directory
        stat =
          size: 4096,
          mode: 0o40777

      else
        # A file
        stat =
          size: info.size,
          mode: +"0o100#{ info.mode }"

      cb(code, stat)

  readdir: (path, cb) =>
    debug("readdir", path)

    list = null
    code = 0

    @store.list path, (err, files) ->
      if err?
        code = -ERRORS[err.code ? 'EIO']

      else
        list = _.map(files, (info) -> Path.basename(info.path))

    cb(code, list)

start = (opts) ->
  client = new Flickr(opts.API_KEY, opts.API_SECRET, opts.ACCESS_TOKEN, opts.ACCESS_SECRET)
  store = new FlickrStore(client, opts)
  handlers = new FlickrFS(store, opts)

  opts.mount = '/Users/zackbloom/mounts/14'
  f4js.start opts.mount, handlers, true
  
  debug "Started at #{ opts.mount }"

module.exports = {FlickrFS, start}
