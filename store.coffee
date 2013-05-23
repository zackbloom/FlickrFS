_ = require('underscore')

Client = require('./client')

class FlickrStore
  constructor: (client, @opts={}) ->
    @client = new Client client, @opts


module.exports = FlickrStore
