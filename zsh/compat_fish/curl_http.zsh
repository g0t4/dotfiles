# curl aliases
ealias curlv="curl -sLv" # -v show request&response + headers&body! # -s hides progress bar when piping output, -L follows redirects
ealias curlI="curl -sSI" # HEAD request only # -S shows error on failure when using -s (silent)
ealias curls="curl -fsSL" # quiet/silent output
# FYI keep only key curl aliases in here...

# httpie aliases
ealias httpg="http GET"
ealias httpp="http PUT"
ealias httph="http HEAD"
ealias httpd="http --download"
ealias httpo="http --offline"
ealias httpv="http --print HhBbm " # show request&response headers&body all! + m = metadata?
# http localhost:8080 name='bob' # submit JSON => COOL
# http example.org X-MyHeader:123 # add a header
# https://github.com/httpie/cli#installation
