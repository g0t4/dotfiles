function _git_unpushed --description "Prints all branches to assess any unpushed commits, in all git repos in the current directory"

    function _abbreviated_path
        # ? add this to my prompt, I am not sure I wanna waste space in the prompt for the org/repo name but maybe that would help, there are noticeable # of times I use pwd b/c I'm unsure which repo I am in, b/c right now prompt is just (basename $PWD)
        set path $argv[1]
        # $HOME/foo => ~/foo
        set path (string replace -r '^'"$HOME" '~' $path)

        # creates variable in default scope per named capture group: (long_host, remainder in this case)
        #     ~/repos/github/g0t4/foo => long_host=github, remainder=g0t4/foo
        #       => gh:g0t4/foo
        set matches (string match --regex '^~/repos/(?<long_host>[^/]*)/(?<remainder>.*)' $path)
        if test -n "$matches"
            # replace common hostnames with shorter aliases
            # probably more useful if I use this in prompt_pwd than to create headers for each repo below
            set long_host (string replace 'github' 'gh' $long_host)
            set long_host (string replace 'gitlab' 'gl' $long_host)
            set long_host (string replace 'bitbucket' 'bb' $long_host)
            set long_host (string replace 'wes-config' '' $long_host)
            echo "$long_host:$remainder"
            return
        end
        echo $path
    end

    function _repo_and_submodules
        set repo_dir $argv[1]
        _repo_status $repo_dir

        # submodules
        for sub in (git -C $repo_dir submodule foreach --quiet 'echo $path')
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
        log_header (_abbreviated_path $repo_dir) # print path (has org and repo)

        # is the repo dirty? (ie uncommitted changes)
        set is_dirty (git -C $repo_dir status --porcelain)
        if test -n "$is_dirty"
            log_error "  DIRTY 🙀🙀🙀"
        end

        # !  PRN get fetch all? before list/test branches

        # show local branches (i.e. is the latest commit pushed to a remote (tracking or otherwise)
        #PAGER= git -C $repo_dir branch -vv # add --all? shouldn't need to see all remove branches
        # ideas for tests to replace just dumping branches:
        #   any local branches that don't have a tracked remotee
        #   any local branch that is ahead/behind its tracked remote


        # --shell => each line of format provides a command and interpolated values are escaped
        #   FYI see man git-ref-for-each for what info is available
        git -C $repo_dir \
            for-each-ref --shell \
            --format="set ref %(refname:short); set upstream %(upstream:short); set push %(push); set upstream_track %(upstream:trackshort); set push_track %(push:trackshort)" \
            refs/heads \
            | while read entry
            # rough first pass at my own emphasis on ref status, I like it! this is instead of using git branch -vv
            eval "$entry"

            # trackshort => < behind , > ahead , <> both, = same
            if is_empty $upstream
                log_ --apple_orange "$ref: no upstream"
            else

                # PRN consider $push too
                if test $upstream_track = '='
                    # = (show but don't highlight it)
                    echo "$ref: $upstream_track ($upstream)"
                else
                    # ahead/behind/gone/both
                    log_ --apple_red "$ref: $upstream_track ($upstream)"
                end
            end
        end


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
