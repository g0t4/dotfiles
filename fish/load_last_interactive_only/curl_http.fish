# curl aliases
abbr curlv "curl -sLv" # -v show request&response + headers&body! # -s hides progress bar when piping output, -L follows redirects
abbr curlI "curl -sSI" # HEAD request only # -S shows error on failure when using -s (silent)
abbr curls "curl --fail-with-body -sSL" # quiet/silent output
abbr curlM "curl --manual"
# FYI keep only key curl aliases in here...

# really would rock if I could tab complete these "anywhere" expansions...
#   having to memorize these defeats the point except for my most commonly used position anywhere abbrs
# abbr --command curl --position anywhere -- ajson "'Accept: application/json'"
# abbr --command curl --position anywhere -- asse "'Accept: text/event-stream'"
# would love to have mime_json, mime_event, etc

# expand short => long options
abbr --command curl --position anywhere -- -d --data
abbr --command curl --position anywhere -- -f --fail
abbr --command curl --position anywhere -- -i --include
abbr --command curl --position anywhere -- -o --output
abbr --command curl --position anywhere -- -O --remote-name
abbr --command curl --position anywhere -- -s --silent
abbr --command curl --position anywhere -- -S --show-error
abbr --command curl --position anywhere -- -v --verbose
abbr --command curl --position anywhere -- -I --head
abbr --command curl --position anywhere -- -H --header
abbr --command curl --position anywhere -- -L --location
abbr --command curl --position anywhere -- -N --no-buffer
abbr --command curl --position anywhere -- -X --request

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
