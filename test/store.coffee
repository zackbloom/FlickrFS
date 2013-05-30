fs = require('fs')
assert = require('assert')
debug = require('debug')('FFS:Test:Store')
{Flickr} = require('flickr-with-uploads')
FlickrStore = require('../store')

config = require('../config')
opts = config.load './fs-flickr.yaml'

flickr = new Flickr(opts.API_KEY, opts.API_SECRET, opts.ACCESS_TOKEN, opts.ACCESS_SECRET)
store = new FlickrStore(flickr)

describe 'storing data', ->
  it 'should get the data it sets', (done) ->
    @timeout 2400000

    path = "/test/path/#{ Math.floor(Math.random() * 10000000000) }"

    size = 1024*1024*32
    buffer = new Buffer(size)
    fs.readSync(fs.openSync('/dev/urandom', 'r'), buffer, 0, size)

    buffer = fs.readFileSync('/Users/zackbloom/Music/Brandi Carlile/03 Closer To You.mp3')
    
    start = +new Date
    debug 'writing'
    store.write 'test/path', buffer, '644', (err, id) ->
      assert.equal(err, null)

      debug 'reading'
      store.read id, (err, data) ->
        debug 'done reading, converting'
        assert.equal buffer.length, data.length
        for i in [0..buffer.length]
          assert.equal buffer[i], data[i]
        debug 'done converting'

        debug "#{ buffer.length / (1024*1024) }MB in #{ (+new Date - start)/1000 }s"
        do done
