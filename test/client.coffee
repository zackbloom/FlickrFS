assert = require('assert')
fs = require('fs')
{Flickr} = require('flickr-with-uploads')

config = require('../config')
FlickrPhotoClient = require('../client')

opts = config.load './fs-flickr.yaml'

flickr = new Flickr(opts.API_KEY, opts.API_SECRET, opts.ACCESS_TOKEN, opts.ACCESS_SECRET)
client = new FlickrPhotoClient flickr

writeTestImage = (cb) ->
  testImage = __dirname + '/babyface.png'
  contents = fs.readFileSync testImage

  path = "/test/path/#{ Math.floor(Math.random() * 10000000000) }"
  stream = fs.createReadStream testImage
  client.writePhoto path, stream, (err, id) ->
    assert.equal(err, null)
    assert.notEqual(id, undefined)

    cb {id, path, contents}

describe.skip 'PhotoClient', ->
  describe 'readInfo', ->
    it 'should get the info by id', (done) ->
      @timeout 10000

      writeTestImage (image) ->
        client.readPhotoInfo image.id, (err, info) ->
          assert.equal(err, null)
          assert.equal(info?.title, client.encodeTitle image.path)

          do done

  describe 'loading', ->
    it 'should load the image it saves', (done) ->
      @timeout 10000

      writeTestImage (image) ->
        client.readPhoto image.id, (err, stream) ->
          assert.equal(err, null)

          data = ''
          stream.on 'data', (buffer) ->
            data += buffer.toString('hex')

          stream.on 'end', ->
            assert.equal(data, image.contents.toString('hex'))

          do done

