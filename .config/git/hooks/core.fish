#!/usr/bin/env fish

set repo (git rev-parse --show-toplevel 2>/dev/null)

if not string match --quiet --regex "/g0t4/[^/]+\$" $repo
    echo not g0t4 repo, skipping...
    return
end

if test -d "$repo/.ctags.d"; and test -f Makefile
    # assume Makefile target for tags
    log_ --apple_pink --bold "make tags"
    make tags
end

if test -f "$repo/.rag.yaml"
    # convention => .rag.yaml config file
    #  that way I explicitly have to make the file and opt-in
    log_ --apple_pink --bold rag_indexer

    #  PRN I should have an option inside to toggle off the auto rag_indexer... that I think can go inside the python code
    #     heck even this check could go into the python code
    rag_indexer --githook
end
