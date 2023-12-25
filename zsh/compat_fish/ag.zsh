alias ag="ag --nogroup" # grouping doesn't show filename+line# so I can't click to open in vscode (in iterm2) hence disable grouping by default

ealias agi="ag -i"
ealias agh="ag --hidden" # search hidden files (including vcs ignores)
ealias agu="ag -u" # unrestricted # by default .gitignore/.hgignore/.ignore are excluded

# I am used to these params, don't currently need to alias them:
#  -g and -G myself
#  -A/-B or -C # num of context lines to show # default = 2 for both

ealias agl="ag -l" # print file name only, not matched content
ealias agL="ag -L" # print files w/o content match
ealias agw="ag --word-regexp" # match whole words
ealias agz="ag --search-zip" # search inside zip files (gz,xz only)
