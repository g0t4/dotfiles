function is_git_repo {
    git rev-parse --is-inside-work-tree 1>/dev/null 2>&1
}

function is_hg_repo {
    hg root >/dev/null 2>&1
}

function git_repo_root {
    git rev-parse --show-toplevel 2>/dev/null
    # return 0
}

function hg_repo_root {
    hg root 2>/dev/null
}

function _repo_root {
    if is_git_repo; then
        git_repo_root
    elif is_hg_repo; then
        hg_repo_root
    else
        echo did not find git repo >&2
        pwd
    fi
}

