#
# TODO - do I want cdn? it is fine for now ealias cdn="cd_to_dir_of"
function cd_to_dir_of
    set -l _type_type $(type --type $argv)
    echo "$_type_type"
    # NOTE: this isn't strictly necessary but I like to see the type :)

    # considerations: behave like cdc (resolve symlinks, parent of file that its defined in, etc)
    #   PRN find a way to locate where an alias is defined and do the same thing for aliases (cd to dir of file that defines alias)
    #   must have (to be diff than cdc): work for shell functions
    # get type:

    # cases:
    # - whence -v _pip # also _ansible
    #     _pip is an autoload shell function
    # - whence -v python3
    #     python3 is /opt/homebrew/bin/python3
    # - whence -v pyenv_prompt_info
    #     pyenv_prompt_info is a shell function from /Users/wes/repos/wes-config/oh-my-zsh/lib/prompt_info_functions.zsh
    # - no path: (for now, TODO is there a way to get path to where any name is defined?)
    #   whence -v agr
    #     agr: aliased to alias | grep -i
    # - not loaded (shell function):
    #   whence -v _ansible # or _pip
    #     _ansible is an autoload shell function
    set -l _type $(type --path $argv)
    or begin
        echo "name not found..."
        # todo ealias lookup?
        return 1
    end

    # note I could match a regex group with grep to avoid space but meh
    cd_to_dir_of_file $_type
end

# cd to the dir that houses a command (follow symlinks)
function cd_to_dir_of_command
    # FYI: this is not 100% same as cdn b/c an alias can take precedence over a command and thus wins out with whence -v (in cdn) but =foo implies first matching command (not aliases,etc) so this would help me cd to command even if it's not first in path to handle a given name... not sure if that's good or bad?
    # ! TODO why did I have this again?
    cd_to_dir_of_file (type --path $argv) #=foo
end

ealias cdc="cd_to_dir_of_command"

# if I pass file to cd it should just go to folder of file
# dereferences symlinks (super useful for the spaghetti from brew installs)
# test with: `cdd =python3.11`
function cd_to_dir_of_file
    # TODO PRN: feels like I should be able to combine this into cdn paradigm (along with cdc)
    #   TODO: if so, use `cdd` for the command as I like that
    set -l _cd_path $argv
    argparse --min 1 -- $argv or return 1

    if test ! -e $_cd_path
        echo "$_cd_path not found"
        return
    end

    # if path is a symlink then fully resolve the target (recursively)
    # echo "0: $_cd_path"
    if test -L $_cd_path
        echo "symlink:\n   $_cd_path =>"
        set _cd_path $(readlink -f $_cd_path)
        # leaving this here as its nice to see when it happens!
        # echo " $_cd_path"
    end

    if test -d $_cd_path
        # if a directory, change right to it (not its parent)
        cd $_cd_path
    else
        # if a file, then cd to its parent
        cd (dirname $_cd_path)
    end

    log_md "cd $(pwd)"
end
ealias cdd="cd_to_dir_of_file "
