function _git_unpushed --description "Prints all branches to assess any unpushed commits, in all git repos in the current directory"
    # I create many repos (ie for courses, projects, etc) and occasionally I review for unpushed commits (peace of mind)
    # Also, this can be helpful for analyzing the status of submodules (perhaps I should look for submodules if PWD is inside of a git repo)

    for f in *
        if ! test -e $f/.git
            # .git is a dir for repos
            # .git is a file for submodules
            # thus just check for existence
            continue
        end

        echo
        log_header $f # print dir name (will have org and repo name so that's perfect right now)

        # is the repo dirty? (ie uncommitted changes)
        set is_dirty (git -C $f status --porcelain)
        if test -n "$is_dirty"
            log_error "  DIRTY 🙀🙀🙀"
        end

        # show local branches (i.e. is the latest commit pushed to a remote (tracking or otherwise)
        PAGER= git -C $f branch -vv # add --all? shouldn't need to see all remove branches
    end
end
