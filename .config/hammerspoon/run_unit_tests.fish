#!/usr/bin/env fish

# TODO as you need more tests, consider how to expand this to full repo

cd $WES_DOTFILES/.config/hammerspoon

# run sets of tests iwth
busted config/macros/screenpal/helpers_tests.lua

# !!! OR use plenary unit test runner in nvim!
#  as long as it can find deps it will work

