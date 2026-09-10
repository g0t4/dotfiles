## BEGIN .NET version helpers
set -l _max_version 9
# TODO try rewriting some/all jq based abbrs to use duckdb? rewrite to use duckdb, i.e. "skopeo/curl | duckdb -c "SELECT * FROM read_json('/dev/stdin');"
# list versions (tags by patch):
abbr dotnet_versions 'skopeo --override-os linux inspect docker://mcr.microsoft.com/dotnet/sdk | jq ".RepoTags | .[]" -r'
# list major versions only:
abbr dotnet_versions_major_only 'skopeo --override-os linux inspect docker://mcr.microsoft.com/dotnet/sdk | jq ".RepoTags | .[]" -r | grep -o "\d\.\d" | sort | uniq'
abbr dotnet_versions_major_only_nightly 'skopeo --override-os linux inspect docker://mcr.microsoft.com/dotnet/nightly/sdk | jq ".RepoTags | .[]" -r | grep -o "\d\.\d" | sort | uniq'
# FYI 2.1 had arm32v7 support which is problematic in my testing on my mac (uses qemu to emulate and run)... so avoid using 2.1 on my m1 mac ... for now... instead use 3.1+ which 3.1 introduced arm64v8 support
function dotnet_get_version_tag
    set ver $argv[1]
    if test $ver = "3" -o $ver = "2"
       echo "$ver.1"
    else
       echo "$ver.0"
    end
end
#
# TODO write as regex abbr(s)?
# generation is too slow at runtime (2-3ms on faster envs)... just let copilot do this for me when new versions are released :) it can do implicit loops and gen the code right here
#   another approach would be to have some sort of gen fwk to compile my startup files into underlying abbr/func/etc and save that and use that in startup and manually compile when I make changes (or pull repo changes)
abbr dn2 'dotnet_version 2.1'
abbr dn3 'dotnet_version 3.1'
abbr dn4 'dotnet_version 4.0'
abbr dn5 'dotnet_version 5.0'
abbr dn6 'dotnet_version 6.0'
abbr dn7 'dotnet_version 7.0'
abbr dn8 'dotnet_version 8.0'
abbr dn9 'dotnet_version 9.0'
abbr dn10 'dotnet_version 10.0'
abbr dn11 'dotnet_version 11.0'

abbr dns2 'dotnet_shell 2.1'
abbr dns3 'dotnet_shell 3.1'
abbr dns4 'dotnet_shell 4.0'
abbr dns5 'dotnet_shell 5.0'
abbr dns6 'dotnet_shell 6.0'
abbr dns7 'dotnet_shell 7.0'
abbr dns8 'dotnet_shell 8.0'
abbr dns9 'dotnet_shell 9.0'
abbr dns10 'dotnet_shell 10.0'
abbr dns11 'dotnet_shell 11.0'

#
#     # FYI src=./ works too but I am going with $PWD to use explicit, absolute path (historically required but now seems to accept relative)
#     docker container run -i -t --rm \
#         --mount type=bind,src=$(pwd),dst=/cwd \
#         --workdir /cwd \
#         mcr.microsoft.com/dotnet/sdk:$_version_tag \
#         dotnet $@
function dotnet_version
    set _version_tag $argv[1]
    set -e argv[1] # Remove the first argument

    # Note: In fish, $PWD is an environment variable, and (pwd) is equivalent. Using $PWD for clarity and directness.
    docker container run -i -t --rm \
        --mount type=bind,src=$PWD,dst=/cwd \
        --workdir /cwd \
        (get_image_url $_version_tag) \
        dotnet $argv
end
function get_image_url
    set _version_tag $argv[1]
    if string match -q "9.0" $_version_tag
        echo "mcr.microsoft.com/dotnet/nightly/sdk:9.0-preview"
        return
    end
    echo "mcr.microsoft.com/dotnet/sdk:$_version_tag"
end
function dotnet_shell
    set _version_tag $argv[1]

    # --mount bind mounts host current directory at /cwd so can access files right away, i.e. `dotnet new console` and keep the new proj
    echo docker container run -i -t --rm \
        --mount type=bind,src=$PWD,dst=/cwd \
        --workdir /cwd \
        (get_image_url $_version_tag) \
        bash

    # FYI if bind mount is not valid, will get warning such as: "docker: Error response from daemon: invalid mount config for type "bind": bind source path does not exist: /Applications/Arc.app." which is perfect for explaining the problem so I don't need to add my own check here
end
#
# diff dotnet command output between versions
function diff_dotnet
    # TODO? warn if $COLUMNS less than 200? (then again sometimes I probably want > 200 so hmmm)

    # usage:
    #    diff_dotnet 3.1 5.0 new -h
    #       diff of help outout for new command between 3.1 and 5.0! works!
    #       avoid 2.1 to 3.1 diff on an m1 mac

    set left_version $argv[1]
    set right_version $argv[2]
    # skip first 2 args, so can use $@ directly and avoid it being treated as quated single arg:
    set -e argv[1]
    set -e argv[1]

    set left_header "$left_version: dotnet $argv"
    set right_header "$right_version: dotnet $argv"
    icdiff --whole-file --highlight \
        --label $left_header \
            (dotnet_version $left_version $argv | psub) \
        --label $right_header \
            (dotnet_version $right_version $argv | psub)

    #! FYI <() failed on surface studio? IIRC>.. anyways use =() which uses tmp files in zsh... also <() uses named pipes that have 8k limit so might as well avoid that issue with massive outputs (if any)
end
#
# diff helper: don't have to type out major version before/after, lookup previous and current major.minor
abbr dnd3 'diff_dotnet 2.1 3.1'
abbr dnd5 'diff_dotnet 3.1 5.0'
# loops are expensive vs inline and the above two are not easily calculated anyways, so just inline (save 1ms+)
abbr dnd6 'diff_dotnet 5.0 6.0'
abbr dnd7 'diff_dotnet 6.0 7.0'
abbr dnd8 'diff_dotnet 7.0 8.0'
abbr dnd9 'diff_dotnet 8.0 9.0'
abbr dnd10 'diff_dotnet 9.0 10.0'
abbr dnd11 'diff_dotnet 10.0 11.0'

function dnd_all
    # helper aliases generated above so can have dnd5_all => dnd_all 5

    # # ! warnings:
    log_ --red 'FYI command list is hardcoded in dnd_all function ... might be missing new/deprecated commands'
    log_ --blue '  FYI if a given command output is completely unchanged it show that entire command (not even when I pass --whole-file to icdiff)'
    log_ --apple_orange '   KEEP in mind => help output is not 100% reflective of actual commands / args avail...' # ie in v7 workload clean isn't in help but it is a command!

    # FYI to add commands to check in here, use dn5h => dnd5 help (help lists commands).. what to do if command no exist for a given version?
    # I LIKE THIS! => and its pretty fast! (plus get results incrementally so I can review while it runs!)
    set _new_version $argv[1]
    eval "dnd$_new_version" help

    eval "dnd$_new_version" new -h
    # .NET 7+ adds subcommands instead of --search => now its search
    if test $_new_version -ge 7
        eval "dnd$_new_version" new create -h
        eval "dnd$_new_version" new install -h
        eval "dnd$_new_version" new uninstall -h
        eval "dnd$_new_version" new update -h
        eval "dnd$_new_version" new search -h
        eval "dnd$_new_version" new list -h
    end
    if test $_new_version -ge 8
        eval "dnd$_new_version" new details -h
    end

    # project manipulation:
    # * I like grouping by purpose (b/c often a change to one of these is in all of these... easy to dedupe)
    eval "dnd$_new_version" add -h
    eval "dnd$_new_version" add package -h
    eval "dnd$_new_version" add reference -h
    eval "dnd$_new_version" remove -h
    eval "dnd$_new_version" remove package -h
    eval "dnd$_new_version" remove reference -h
    eval "dnd$_new_version" list -h
    eval "dnd$_new_version" list package -h
    eval "dnd$_new_version" list reference -h
    eval "dnd$_new_version" sln -h
    eval "dnd$_new_version" sln package -h
    eval "dnd$_new_version" sln reference -h

    eval "dnd$_new_version" clean -h
    eval "dnd$_new_version" restore -h
    eval "dnd$_new_version" build -h
    eval "dnd$_new_version" build-server -h
    eval "dnd$_new_version" build-server shutdown -h

    eval "dnd$_new_version" run -h

    eval "dnd$_new_version" test -h

    eval "dnd$_new_version" pack -h
    eval "dnd$_new_version" publish -h

    eval "dnd$_new_version" store -h
    eval "dnd$_new_version" tool -h
    eval "dnd$_new_version" tool install -h
    eval "dnd$_new_version" tool uninstall -h
    eval "dnd$_new_version" tool update -h
    eval "dnd$_new_version" tool list -h
    eval "dnd$_new_version" tool run -h

    log_ --red 'use dnd_tools for nuget/msbuild/vstest/etc'

    # prominent bundled tool, so include it here
    eval "dnd$_new_version" watch -h
    eval "dnd$_new_version" watch run -h
    eval "dnd$_new_version" watch test -h

    # 6.0+ added subcommands: format, sdk, workload
    #   FYI 7 and 8 didn't add any top level commands
    if test $_new_version -ge 6
        eval "dnd$_new_version" format -h
        eval "dnd$_new_version" sdk -h
        eval "dnd$_new_version" workload -h
        # workload subcommands: install, update, list, search, uninstall, repair, restore

        eval "dnd$_new_version" workload install -h
        eval "dnd$_new_version" workload uninstall -h

        eval "dnd$_new_version" workload update -h

        eval "dnd$_new_version" workload repair -h
        eval "dnd$_new_version" workload restore -h

        eval "dnd$_new_version" workload list -h
        eval "dnd$_new_version" workload search -h

        # 8.0 added clean subsub
        if test $_new_version -ge 8
            eval "dnd$_new_version" workload clean -h
        end
    end

end
function dnd_tools
    # other tools that have interface via dotnet command
    set _new_version $argv[1]

    eval "dnd$_new_version" vstest --help # nested command, might not want full diff? though its not too long so might be useful to see changes that correspond across dotnet/vstest/etc tools
    eval "dnd$_new_version" msbuild -help # lets try full command
    eval "dnd$_new_version" nuget --help # just version of nested commands

    # ! could add in prominent tools bundled and dump their help too
end
#
## * END DIFF HELPERS

#! FYI `dn` overlaps with `docker network`=`dne` and `docker node`=`dno`...
#!    DO NOT USE `dno` or `dne` for dotnet aliases => s/b fine as no subcommands currently exist with e/o as first letter
# FYI `dot` conflicts with `dot` command... plus its awkward to type so I abandoned that prefix

# abbr dnnuget 'dotnet nuget'

# * help
# https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-help
abbr dnh 'dotnet -h'
abbr dnhh 'dotnet help help'
abbr dnd 'dotnet --diagnostics'
abbr dnsdks 'dotnet --list-sdks'
abbr dnsdkc 'dotnet sdk check'
abbr dnrtms 'dotnet --list-runtimes'
abbr dni 'dotnet --info'

# * package / reference management commands
abbr dnres 'dotnet restore' # packages
abbr dnap 'dotnet add package'
abbr dnar 'dotnet add reference'
abbr dnha 'dotnet help add' # https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-add-reference
abbr dna 'dotnet remove' # package or ref
abbr dnsln 'dotnet sln' # manage solution files
abbr dnhsln 'dotnet help sln'
abbr dnls 'dotnet list -h'
abbr dnlsp 'dotnet list package' # package refs
abbr dnlsr 'dotnet list reference' # project to project
abbr dnstore 'dotnet store' # runtime package store

abbr dnn 'dotnet new'
abbr dnnls 'dotnet new list'
abbr dnni 'dotnet new install'
abbr dnnu 'dotnet new uninstall'
abbr dnnup 'dotnet new update'
abbr dnns 'dotnet new search'
abbr dnnd 'dotnet new details'
# https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-new (BTW repo backed docs)

# testing
#abbr dntest 'dotnet test' # newer/higher level test api
#abbr dnvst 'dotnet vstest' # lower level api for testing IIRC

# bundled tools:
abbr dndc 'dotnet dev-certs'
abbr dnfsi 'dotnet fsi'
abbr dnsqlc 'dotnet sql-cache'
abbr dnusec 'dotnet user-secrets'

# create artifacts (builds, deploys, packages, etc)
abbr dnc 'dotnet clean'
abbr dnb 'dotnet build'
abbr dnbs 'dotnet build-server'
abbr dnmsb 'dotnet msbuild'
abbr dnpa 'dotnet pack'
abbr dnpu 'dotnet publish'
:
# run artifacts
abbr dnr 'dotnet run'
abbr dnw 'dotnet watch'

# https://docs.microsoft.com/en-us/dotnet/core/tools/global-tools
abbr dnt 'dotnet tool -h'
abbr dnht 'dotnet help tool'
abbr dntls 'dotnet tool list'
abbr dnhtls 'dotnet tool list'
abbr dntlsl 'dotnet tool list --locaa'
abbr dntlsg 'dotnet tool list --global'
abbr dnts 'dotnet tool search'
abbr dntsd 'dotnet tool search --detail'
abbr dnti 'dotnet tool install'
abbr dntun 'dotnet tool uninstall'
abbr dntup 'dotnet tool update'
abbr dntr 'dotnet tool run'
abbr dntres 'dotnet tool restore'
