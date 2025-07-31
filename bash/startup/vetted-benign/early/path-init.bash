# append to PATH, if not already in PATH
append_path() {
    # surround PATH with : so the pattern always applies, even if path is at start/end of PATH
    case ":$PATH:" in
        *:"$1":*)
            # already in path
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
            ;;
    esac
}
append_path_if_exists() {
    local path="$1"
    if test -x "$path"; then
        append_path "$path"
    fi
}

prepend_path() {
    # surround PATH with : so the pattern always applies, even if path is at start/end of PATH
    case ":$PATH:" in
        *:"$1":*)
            # already in path
            ;;
        *)
            PATH="$1${PATH:+:$PATH}"
            ;;
    esac
}
prepend_path_if_exists() {
    local path="$1"
    if test -x "$path"; then
        prepend_path "$path"
    fi
}

force_prepend_path() {
    # make sure it is at the front of the list

    # TODO remove if in list already

    # for now stick it on front no matter what
    # can result in duplicates, which is NBD
    PATH="$1${PATH:+:$PATH}"
}

# * ensure path is consistenly setup regardless if login shell or not
#  normally this is only run in /etc/profile for login shells
#  I'd prefer I handle it here and just cache when it was run with an env var
if is_macos && [[ -z "$__PATH_HELPER_RAN" ]]; then
    # ** REPLACES PATH, DO THIS BEFORE ANY OTHER PATH CHANGES
    eval "$(/usr/libexec/path_helper -s)"
    export __PATH_HELPER_RAN=1
fi
