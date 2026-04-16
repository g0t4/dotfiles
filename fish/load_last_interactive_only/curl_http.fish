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

# example websites for testing curl/httpie
abbr curl_test_github "curl https://api.github.com/users/g0t4"
abbr http_test_github "https api.github.com/users/g0t4"
abbr http_test_httpbin "http httpbin.org/get" # http: w/o redirect
#
abbr curl_test_icanhazdadjoke "curl https://icanhazdadjoke.com/"
abbr http_test_icanhazdadjoke "https icanhazdadjoke.com Accept:application/json"
abbr curl_test_wtfismyip "curl https://wtfismyip.com/json"
abbr http_test_wtfismyip "https wtfismyip.com/json"
