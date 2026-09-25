"""Generated from fish/load_last_interactive_only/curl_http.fish; edit Fish/Zsh and rerun the generator."""

from wes_abbreviations import abbr

SOURCE_FUNCTIONS = ()


def register_http_abbreviations():
    abbr('curlv', 'curl -sLv')
    abbr('curlI', 'curl -sSI')
    abbr('curls', 'curl --fail-with-body -sSL')
    abbr('curlM', 'curl --manual')
    abbr('-d', '--data', position="anywhere", commands=('curl',))
    abbr('-f', '--fail', position="anywhere", commands=('curl',))
    abbr('-i', '--include', position="anywhere", commands=('curl',))
    abbr('-o', '--output', position="anywhere", commands=('curl',))
    abbr('-O', '--remote-name', position="anywhere", commands=('curl',))
    abbr('-s', '--silent', position="anywhere", commands=('curl',))
    abbr('-S', '--show-error', position="anywhere", commands=('curl',))
    abbr('-v', '--verbose', position="anywhere", commands=('curl',))
    abbr('-I', '--head', position="anywhere", commands=('curl',))
    abbr('-H', '--header', position="anywhere", commands=('curl',))
    abbr('-L', '--location', position="anywhere", commands=('curl',))
    abbr('-N', '--no-buffer', position="anywhere", commands=('curl',))
    abbr('-X', '--request', position="anywhere", commands=('curl',))
    abbr('httpg', 'http GET')
    abbr('httpp', 'http PUT')
    abbr('httph', 'http HEAD')
    abbr('httpd', 'http --download')
    abbr('httpo', 'http --offline')
    abbr('httpv', 'http --print HhBbm ')
    abbr('curl_test_github', 'curl https://api.github.com/users/g0t4')
    abbr('http_test_github', 'https api.github.com/users/g0t4')
    abbr('http_test_httpbin', 'http httpbin.org/get')
    abbr('curl_test_icanhazdadjoke', 'curl https://icanhazdadjoke.com/')
    abbr('http_test_icanhazdadjoke', 'https icanhazdadjoke.com Accept:application/json')
    abbr('curl_test_wtfismyip', 'curl https://wtfismyip.com/json')
    abbr('http_test_wtfismyip', 'https wtfismyip.com/json')
