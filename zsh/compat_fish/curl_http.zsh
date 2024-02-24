# curl aliases
eabbr curlv "curl -sLv" # -v show request&response + headers&body! # -s hides progress bar when piping output, -L follows redirects
eabbr curlI "curl -sSI" # HEAD request only # -S shows error on failure when using -s (silent)
eabbr curls "curl -fsSL" # quiet/silent output
# FYI keep only key curl aliases in here...

# httpie aliases
eabbr httpg "http GET"
eabbr httpp "http PUT"
eabbr httph "http HEAD"
eabbr httpd "http --download"
eabbr httpo "http --offline"
eabbr httpv "http --print HhBbm " # show request&response headers&body all! + m = metadata?
# http localhost:8080 name='bob' # submit JSON => COOL
# http example.org X-MyHeader:123 # add a header
# https://github.com/httpie/cli#installation
