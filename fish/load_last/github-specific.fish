
abbr ghrc gh_repo_create_private
function gh_repo_create_private
    set __repo_name "$argv"
    if string match --quiet $__repo_name ""
        log_error "No repo name provided, aborting..."
        return -1
    end

    # my convention is to prefix repo name w/ private- => esp b/c I often have corresponding public repos (ie for courses) and this makes it easier to find the private one or public one
    if not string match --quiet --regex "private-*" $__repo_name
        set __repo_name "private-$__repo_name"
    end

    if not gh repo create --private $__repo_name
        log_error "Failed to create repo..."
        return -1
    end

    __gh_repo_create_clone_with_ignores $__repo_name
end

abbr ghrcp gh_repo_create_public
function gh_repo_create_public
    set __repo_name "$argv"
    if string match --quiet $__repo_name ""
        log_error "No repo name provided, aborting..."
        return -1
    end

    if not gh repo create --public $__repo_name
        log_error "Failed to create repo..."
        return -1
    end

    __gh_repo_create_clone_with_ignores $__repo_name
    if string match --quiet --regex "^course" $__repo_name
        for r in (seq 1 10)
            log_ --red "Does this course require 'main' branch? If so set it manually"
        end
    end

end

function __gh_repo_create_clone_with_ignores
    set __repo_name "$argv"

    if not wcl $__repo_name
        log_error "Failed to wcl..."
        return -1
    end

    if not z $__repo_name
        log_error "Failed to z..."
        return -1
    end

    commit_gitignores_for macos linux windows archives images video vim
    # PRN add to zsh's z history databaseend
end


function __gh_depoliticize
    # gh repo list  --json name,defaultBranchRef,isPrivate,isFork g0t4 --limit 1000 > tmp
    # cat tmp | jq 'map(select(.defaultBranchRef.name == "main" and .isFork == false and (.name | startswith("course") | not)))'
    #
    # check for local repos that might be on wrong branch
    # for f in *; test -d $f; and echo -n $f"   "; and git -C $f branch --show-current  ;end | grep main | grep -v "^course"


    # FYI this assumes currently on main, no master branch... it switches for that scenario only and removes main
    # hence aborts when not on expected branch

    # open page to view before/after, can check this after done with changes by refreshing
    gh repo view --web

    if not git pull --rebase
        echo "Failed to pull latest, aborting..."
        return -1
    end

    # list all branches before
    git branch -a

    if not git status | grep -q "On branch main"
        echo "Not on main branch, aborting..."
        return -1
    end

    # create master if not exists
    if not git branch -a | grep -q master
        git checkout -b master
        git push --set-upstream origin $(git_current_branch)
    end

    # ok to recall
    gh repo edit --default-branch master

    if not git status | grep -q "On branch master"
        echo "Not on master branch, aborting..."
        return -1
    end

    if not git branch -d main
        echo "Failed to delete main branch, aborting..."
        return -1
    end

    git push origin --delete main


end
