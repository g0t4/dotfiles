# ealias .. 'cd ../'
# ealias ... 'cd ../../'
# etc
for ($i = 2; $i -le 9; $i++) {
    $name = '.' * $i
    $iminus1 = $i - 1
    $value = '../' * $iminus1
    ealias "$name" "cd $value"
}


function tree() {
    # choco install tree --yes

    tree.exe -I 'node_modules|bower_components|.git' `
        -A --noreport --dirsfirst $args

    # func b/c need to pass args & compose into further aliases below (those can expand)
    # -A ansi style level lines - looks clean!
    # -F (trailing / * etc like ls)
    # -I are ignored directories (even if use -a for all files, still ignores -I stuffs which is what I want)
    # --noreport : no summary/count of dirs/files
}
ealias treea "tree -a" # all files (minus of course -I ignores)
ealias treed "tree -d" # dirs only
ealias treeh "tree -h" # human readable sizes
1..9 | ForEach-Object { ealias "tree$_" "tree -L $_" } # tree -L 1
ealias treeP "tree -P" # -P PATTERN # opposite of -I PATTERN
# tree --help # list all args

function cdr() {
    # PRN add hg_repo_root and make generic repo_root for both:
    Set-Location $(git_repo_root)
}


function take {
    param ( [string] $path )
    mkdir -p $path
    Set-Location $path
}
