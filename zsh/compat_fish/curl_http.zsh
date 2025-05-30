# curl aliases
abbr curlv "curl -sLv" # -v show request&response + headers&body! # -s hides progress bar when piping output, -L follows redirects
abbr curlI "curl -sSI" # HEAD request only # -S shows error on failure when using -s (silent)
abbr curls "curl --fail-with-body -sSL" # quiet/silent output
# FYI keep only key curl aliases in here...

# httpie aliases
abbr httpg "http GET"
abbr httpp "http PUT"
abbr httph "http HEAD"
abbr httpd "http --download"
abbr httpo "http --offline"
abbr httpv "http --print HhBbm " # show request&response headers&body all! + m = metadata?
# http localhost:8080 name='bob' # submit JSON => COOL
# http example.org X-MyHeader:123 # add a header
# https://github.com/httpie/cli#installation
