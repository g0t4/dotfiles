~/.inpurc is readline's user specific startup/config file,
if this isn't present, it will fallback to /etc/inputrc

## bash docs re: readline

- FYI `man bash` has awesome, detailed explanations of configuring readline

### CRITICAL NOTES for composite keyseq => multiple actions

These are from my work on abbr.bash to get Return to trigger abbr expand AND the submit command (accept-line):

```bash
# man bash => search for `/bind readline-command-line`:
#   bind a key sequence to...
#   - _a_ readline function   # SINGLE
#   - or macro                # MULTIPLE if macro contains key sequences!
#   - or to _a_ shell command # SINGLE
#
# TLDR, use a macro with embedded key sequences to trigger multiple OTHER keymaps
# - same conclusion here: https://stackoverflow.com/questions/22224657/custom-readline-functions-in-bash-commandline

# * keymap to macro:
bind '"\C-x": "macro"' # macros are quoted
bind '"\C-x": "hello there"' # inserts "hello there"
bind '"\C-x": "\C-b\C-d"' # expands to trigger key sequence(s)... just put in key sequences back to back, no delimiter
# equivalent to typing/pasting the text
# w/ backslashes expanded... thus you can use this to trigger other key sequences
#  and that gives you a mechanism for composite keymaps where one keymap triggers two or more sequences
#
# * keymap to SINGLE readline func:
bind '"\C-x": single-readline-function' # NOT quoted
# bind -l # list readline function names
#
# * keymap to SINGLE bash shell func:
bind -x '"\C-x": single_bash_function' # NOT quoted, MUST ADD -x

# * confirm keymaps:
# bind -p # view keymaps that call readline funcs
# bind -s # view keymaps that call macros
# TODO is there any way to see keymaps that call bash functions (single_bash_function)?
#   I do not see mine listed anywhere (i.e. for expand_abbr via space, nor the composite I use for "enter" from abbr.bash)

```

### /Readline Key Bindings

```readline
# macros insert text (surrounded by '/")
"\C-x\C-r": "macro inserts text"
Control-x: "macro" # symbolic key syntax
# "\C-x\C-r": "\n" # backslash escapes are expanded (so in this case new line is literally inserted, thus submitting the command line)

# bind to commands/functions - no '/" around command name
"\C-u": universal-argument
Control-u: universal-argument
"\e[A": history-search-backward
"\e[B": history-search-forward
```

### /Readline Variables

```bash
bash -V # "human readable" list of readline vars
bash -v # machine format (format that you can run to recreate)

# set via bind:
bind 'set page-completions on'
# basically the bind command takes a line that you would otherwise put in ~/.inputrc

# i.e.:
bind -v | grep keyseq
# set keyseq-timeout 500
```

```readline
# syntax:
set variable-name value
# most values are On/1 or Off
# silently ignores unrecognized names

set bell-style none # disable bell!

# FYI ambiguous key sequence delay just like vim's timeoutlen...
set keyseq-timeout 300 # drop delay from defaul of 500ms

set blink-matching-paren on # off default when insert parens, the last one, jump cursor to other one briefly and return

# comment-begin (“#”) # default bound to M-# (comment out current line so you don't have to move to front and do that, start new, empty cmdline too)

# completion-* # completion related
#   TODO look into more customizations for completion

# enable-bracketed-paste (On) on by default
# history-size # unset by default (bash sets to HISTSIZE by default)
# horizontal-scroll-mode (Off) # don't wrap

set show-all-if-ambiguous on # default off... OMG just show completion on first tab, thank you!

```
