fs = require('fs')
assert = require('assert')
{Flickr} = require('flickr-with-uploads')
FlickrStore = require('../store')

config = require('../config')
opts = config.load './fs-flickr.yaml'

flickr = new Flickr(opts.API_KEY, opts.API_SECRET, opts.ACCESS_TOKEN, opts.ACCESS_SECRET)
store = new FlickrStore(flickr)

describe 'storing data', ->
  it 'should get the data it sets', (done) ->
    @timeout 7500

    path = "/test/path/#{ Math.floor(Math.random() * 10000000000) }"

    size = 1024*32
    buffer = new Buffer(size)
    fs.readSync(fs.openSync('/dev/urandom', 'r'), buffer, 0, size)

    store.write 'test/path', buffer, (err, id) ->
      assert.equal(err, null)

      store.read id, (err, data) ->
        assert.equal buffer.toString('hex'), data.toString('hex')

        do done
