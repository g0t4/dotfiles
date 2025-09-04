#!/usr/bin/env fish

# MUST be in this dir for require calls to work w/in your codebase
cd $WES_DOTFILES/.config/hammerspoon

# add more test files here:
busted config/macros/screenpal/tests.lua

# !!! OR use plenary unit test runner in nvim!
# as long as it can find deps it will work
# - most testing will work if you modify package.path
# - and/or do not require ("hs.*") top level, IOTW stick with hs.* globals API in code that the test runner won't hit
# careful with using vim deps though
# - fine for one off test troubleshooting, i.e. vim.print
# - don't use in prod code unless you are copying over that vim module into your hammerspoon config!
#   which by the way you did copy some of it over, i.e. vim.iter
