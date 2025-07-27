
# append to PATH, if not already in PATH
append_path () {
    # surround PATH with : so the pattern always applies, even if path is at start/end of PATH
    case ":$PATH:" in
        *:"$1":*)
            # already in path
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}
prepend_path() {
    # surround PATH with : so the pattern always applies, even if path is at start/end of PATH
    case ":$PATH:" in
        *:"$1":*)
            # already in path
            ;;
        *)
            PATH="$1${PATH:+:$PATH}"
    esac
}
