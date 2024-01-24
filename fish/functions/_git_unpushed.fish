function _git_unpushed --description "Prints all branches to assess any unpushed commits, in all git repos in the current directory"


    function _repo_and_submodules
        set repo_dir $argv[1]
        _repo_status $repo_dir

        # submodules
        for sub in (git -C $repo_dir submodule foreach --quiet 'echo $path')
            # ? TODO indent status for submodules (would make it possible to move submodules into _repo_status)
            # log_header "  $sub" # for now indent the submodule path
            _repo_status $repo_dir/$sub
        end
    end

    function _child_repos
        set dir $argv[1]
        for entry in $dir/*
            _repo_status $entry
        end
    end

    function _repo_status

        set repo_dir $argv[1]

        if ! test -e $repo_dir/.git
            # .git is a dir for repos
            # .git is a file for submodules
            # thus just check for existence
            return
        end

        log_blankline
        log_header $repo_dir # print path (has org and repo)

        # is the repo dirty? (ie uncommitted changes)
        set is_dirty (git -C $repo_dir status --porcelain)
        if test -n "$is_dirty"
            log_error "  DIRTY 🙀🙀🙀"
        end

        # !  PRN get fetch all? before list/test branches

        # show local branches (i.e. is the latest commit pushed to a remote (tracking or otherwise)
        PAGER= git -C $repo_dir branch -vv # add --all? shouldn't need to see all remove branches
        # ideas for tests to replace just dumping branches:
        #   any local branches that don't have a tracked remotee
        #   any local branch that is ahead/behind its tracked remote
    end


    # I create many repos (ie for courses, projects, etc) and occasionally I review for unpushed commits (peace of mind)

    set repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test $status -eq 0
        # current dir is a repo
        _repo_and_submodules $repo_root
        # prn in future I could do submodules for all repos and then this would just be _repo_status $repo_root
    else
        # current dir is not a repo
        _child_repos $PWD
    end

end
