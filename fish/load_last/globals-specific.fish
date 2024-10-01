
# use p(ext) unless prominent, in which use shortened p(e) format (ensure not gonna need to not expand that often)
abbr --position anywhere -- pbat '| bat -l'
abbr --position anywhere -- pgr '| grep -i'
abbr --position anywhere -- phelp '| bat -l help'
abbr --position anywhere -- pini '| bat -pl ini'
abbr --position anywhere -- pjq '| jq .' # shortened
abbr --position anywhere -- pmd '| bat -pl md' # shortened
abbr --position anywhere -- prb '| bat -pl rb'
abbr --position anywhere -- psh '| bat -pl sh'
abbr --position anywhere -- pxml '| bat -l xml' # shortened
abbr --position anywhere -- pyml '| bat -l yml' # shortened

abbr --position anywhere -- hC '| hexdump -C'
# i.e.    echo -n $IFS | hexdump -C

abbr --position anywhere -- pxargs '| xargs -I {} -- echo {}'
# PRN helper for multiple commands or complex commands pased to xargs
#   dpkg -L cups-browsed | xargs -I {} sh -c 'test -d "{}" && echo "{}"'
#     lightning fast in bash relative to fish -c overhead
#     *** just use bash or /bin/sh -c # plenty fast and likely suits my needs most of the time
# apt helpers

# *** treeify ideas and working commands:

function dpkg_L_files
    dpkg -L $argv | xargs -I {} echo 'test ! -d "{}"; echo "{}"' | source
end

if not command -q treeify
    function treeify
        echo "treeify not installed, please install it with 'cargo install treeify'"
    end
end

# ask o1-mini to "write me a fish shell function that runs dpkg -L foo on a package and then takes the output and formats it in a tree hierarchy like the tree command"
# this works, have not yet reviewed it... wanna save that for later video.. as I also found `cargo install treeify`
function dpkg_tree_awk
  if not set -q argv[1]
    echo "Usage: dpkg_tree_awk <package_name>"
    return 1
  end

  set pkg $argv[1]

  dpkg -L $pkg | sort | awk '
  BEGIN {
      FS="/"
  }
  {
      # Remove empty first field if path starts with /
      start = 1
      if ($1 == "") {
          start = 2
      }
      # Print indentation
      for (i = start; i < NF; i++) {
          printf "    "
      }
      # Print the current directory or file
      print "└── " $NF
  }'
end
# TODO ask it to fix how disjoint things look at times, also to remove that first needless later of nesting, edge case
# └── .
#     └── lib.usr-is-merged
# └── etc
#     └── apparmor.d
#         └── usr.sbin.cups-browsed
#     └── cups
#         └── cups-browsed.conf
# └── lib
#     └── systemd
#         └── system
#             └── cups-browsed.service
# └── usr
#     └── lib
#         └── cups
