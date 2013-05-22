http = require('http')
exec = require('child_process').exec
URL = require('url')
OAuth = require('oauth')

listenForAuthResponse = (cb) ->
  server = http.createServer (req, res) ->
    return unless /\/authorized/.test(req.url)

    res.end('Successfully Authenticated! Return to the terminal to continue.')

    url = URL.parse(req.url, true)
    cb url.query.oauth_verifier

  server.listen(8088, '127.0.0.1')

auth = (opts, cb) ->
  oauth = new OAuth.OAuth(
    'http://www.flickr.com/services/oauth/request_token',
    'http://www.flickr.com/services/oauth/access_token',
    opts.API_KEY,
    opts.API_SECRET,
    '1.0A',
    null,
    'HMAC-SHA1'
  )

  requestParams =
    oauth_callback: 'http://localhost:8088/authorized'

  oauth.getOAuthRequestToken requestParams, (err, token, secret, res) ->
    if err
      console.error "Error getting request token", err
      return cb(err)

    url = "http://www.flickr.com/services/oauth/authorize"
    url += "?oauth_token=#{ token }"

    exec "open #{ url }", (err) ->
      if err
        console.error "Error opening browser", err
        return cb(err)

      listenForAuthResponse (verifier) ->
        oauth.getOAuthAccessToken token, secret, verifier, (err, accessToken, accessSecret, res) ->
          if err
            console.error "Error getting access token", err
            return cb(err)

          cb(null, accessToken, accessSecret)

module.exports = auth
