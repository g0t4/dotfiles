"""Generated from fish/load_last_interactive_only/curl_http.fish; edit Fish/Zsh and rerun the generator."""

from wes_abbreviations import abbr

SOURCE_FUNCTIONS = ()


def register_http_abbreviations():
    abbr('curlv', 'curl -sLv')  # Source line 2
    abbr('curlI', 'curl -sSI')  # Source line 3
    abbr('curls', 'curl --fail-with-body -sSL')  # Source line 4
    abbr('curlM', 'curl --manual')  # Source line 5
    abbr('-d', '--data', position="anywhere", commands=('curl',))  # Source line 15
    abbr('-f', '--fail', position="anywhere", commands=('curl',))  # Source line 16
    abbr('-i', '--include', position="anywhere", commands=('curl',))  # Source line 17
    abbr('-o', '--output', position="anywhere", commands=('curl',))  # Source line 18
    abbr('-O', '--remote-name', position="anywhere", commands=('curl',))  # Source line 19
    abbr('-s', '--silent', position="anywhere", commands=('curl',))  # Source line 20
    abbr('-S', '--show-error', position="anywhere", commands=('curl',))  # Source line 21
    abbr('-v', '--verbose', position="anywhere", commands=('curl',))  # Source line 22
    abbr('-I', '--head', position="anywhere", commands=('curl',))  # Source line 23
    abbr('-H', '--header', position="anywhere", commands=('curl',))  # Source line 24
    abbr('-L', '--location', position="anywhere", commands=('curl',))  # Source line 25
    abbr('-N', '--no-buffer', position="anywhere", commands=('curl',))  # Source line 26
    abbr('-X', '--request', position="anywhere", commands=('curl',))  # Source line 27
    abbr('httpg', 'http GET')  # Source line 30
    abbr('httpp', 'http PUT')  # Source line 31
    abbr('httph', 'http HEAD')  # Source line 32
    abbr('httpd', 'http --download')  # Source line 33
    abbr('httpo', 'http --offline')  # Source line 34
    abbr('httpv', 'http --print HhBbm ')  # Source line 35
    abbr('curl_test_github', 'curl https://api.github.com/users/g0t4')  # Source line 41
    abbr('http_test_github', 'https api.github.com/users/g0t4')  # Source line 42
    abbr('http_test_httpbin', 'http httpbin.org/get')  # Source line 43
    abbr('curl_test_icanhazdadjoke', 'curl https://icanhazdadjoke.com/')  # Source line 45
    abbr('http_test_icanhazdadjoke', 'https icanhazdadjoke.com Accept:application/json')  # Source line 46
    abbr('curl_test_wtfismyip', 'curl https://wtfismyip.com/json')  # Source line 47
    abbr('http_test_wtfismyip', 'https wtfismyip.com/json')  # Source line 48
