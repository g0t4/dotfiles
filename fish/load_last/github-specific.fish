
abbr ghrc gh_repo_create_private
function gh_repo_create_private
    set __repo_name "$argv"
    if string match $__repo_name ""
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
    if string match $__repo_name ""
        log_error "No repo name provided, aborting..."
        return -1
    end

    if not gh repo create --public $__repo_name
        log_error "Failed to create repo..."
        return -1
    end

    __gh_repo_create_clone_with_ignores $__repo_name
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
