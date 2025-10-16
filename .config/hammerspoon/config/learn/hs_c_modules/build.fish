#!/usr/bin/env fish

clang -bundle -fPIC \
    -I/opt/homebrew/include/lua5.4 \
    -L/opt/homebrew/lib -llua \
    -o ~/.hammerspoon/hello.so hello.c

# PRN add a ~/.hammerspoon/extensions dir if I start using my own custom extensions

# * usage
# FYI copy it to a directory in lua's package.cpath:
#  for path in package.cpath:gmatch("[^;]+") do print(path) end
#
# require("hello").world() => "Hello, world!"

# * MORE EXAMPLES
#  https://github.com/asmagill/hammerspoon_asm
