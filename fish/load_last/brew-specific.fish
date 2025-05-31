

# PURPOSE:
#    combine `brew search foo` with analytics information to show install counts to gauge which packages are more popular (i.e. possibly better supported)

# FYI analytics: https://formulae.brew.sh/analytics/ (click through to find json files with current data)

function _brew_analytics_formula_annual
    if test -z "$tmp_formula_json"
        # check if a tmp file _NAME_ is generated, if not then first call should create it:
        #   DO NOT GENERATE THIS ON SHELL STARTUP, takes 4 to 6ms to call mktemp!!!
        #   -u => don't create file (dry-run)
        set -g tmp_formula_json (mktemp -u) # 4ms to do this!!!! even with -u ... wtf
    end

    if ! test -e $tmp_formula_json
        curl --fail-with-body -sSL https://formulae.brew.sh/api/analytics/install/365d.json >$tmp_formula_json
    end
    cat $tmp_formula_json
end

function _brew_analytics_cask_annual
    if test -z "$tmp_cask_json"
        # check if a tmp file _NAME_ is generated, if not then first call should create it:
        set -g tmp_cask_json (mktemp -u) # 4ms to do this!!!! even with -u ... wtf
    end

    if ! test -e $tmp_cask_json
        curl --fail-with-body -sSL https://formulae.brew.sh/api/analytics/cask-install/365d.json >$tmp_cask_json
    end
    cat $tmp_cask_json
end

function _brew_search_with_analytics

    # *** args
    argparse stars -- $argv # strips out --stars => into _flag_stars
    set query $argv[1]

    # test with:
    #    _reload_config; _brew_search_with_analytics foo

    # PRN keep bold white + green checkmark for installed packages?

    set _formulae (brew search --formula $query)
    # set formula fox fop fio # hard code to test

    # split items (on " ") and trim \n on last item with gsub
    #   this builds an array of formula names that can be used below with IN operator to match on analytics by formula name
    set _formulae_names_array_json (echo $_formulae | jq -R -s -c 'split(" ") |  map(select(length > 0) | gsub("\n$"; ""))')
    begin
        echo -n FORMULA\tRANK\tINSTALLS\tPERCENT # header
        if test -z $_flag_stars
            echo
        else
            echo -e "\tSTARS\tFORKS"
        end

        # sample analytics record: {"number":325,"formula":"minikube","count":"131,246","percent":"0.06"}
        set analytics_records (_brew_analytics_formula_annual | jq -r --argjson formulae_names $_formulae_names_array_json '.items[] | select(.formula | IN($formulae_names[])) | [.formula, .number, .count, .percent] | @tsv ')
        # loop over each record so I can append columns:
        for record in $analytics_records
            set name (echo $record | awk '{print $1}')
            echo -n $record

            if test -z $_flag_stars
                echo
                continue
            end

            set repo_url (brew info --formula $name --json | jq '.[].urls.head | .url' -r)
            # might need to scrub repo_url to org/repo format (like my wcl command)
            #   and only do stars lookup if it is a github repo
            set stars_forks (gh repo view $repo_url --json stargazerCount,forkCount)
            if test $status = 0
                set stars (echo $stars_forks | jq '.stargazerCount')
                set forks (echo $stars_forks | jq '.forkCount')
                echo -e "\t$stars\t$forks"
            else
                echo
            end

            # PRN add other analytics too? or instead?
        end

    end | column -t
    echo # blank line

    set _casks (brew search --cask $query)
    set _casks_names_array_json (echo $_casks | jq -R -s -c 'split(" ") |  map(select(length > 0) | gsub("\n$"; ""))')
    begin
        echo -n -e CASK\tRANK\tINSTALLS\tPERCENT # header
        if test -z $_flag_stars
            echo
        else
            echo -e \tSTARS\tFORKS
        end


        set analytics_records (_brew_analytics_cask_annual | jq -r --argjson cask_names $_casks_names_array_json '.items[] | select(.cask | IN($cask_names[])) | [.cask, .number, .count, .percent] | @tsv ')
        for record in $analytics_records
            set name (echo $record | awk '{print $1}')
            echo -n $record

            echo # tmp disable stars:
            # if test -z $_flag_stars
            #     echo
            #     continue
            # end
            #
            # set repo_url (brew info --cask $name --json=v2 # TODO ... urls are diff vs formula) ... maybe I shouldn't bother with getting repo url on casks and only do it for formula for now which intuitively makes sense given formula are built from src whereas cask can be close/open source
            #   TODO ERROR => Cannot specify `--cask` when using `--json=v1`!
            #
            # # might need to scrub repo_url to org/repo format (like my wcl command)
            # #   and only do stars lookup if it is a github repo
            # set stars_forks (gh repo view $repo_url --json stargazerCount,forkCount)
            # if test $status = 0
            #     set stars (echo $stars_forks | jq '.stargazerCount')
            #     set forks (echo $stars_forks | jq '.forkCount')
            #     echo -e "\t$stars\t$forks"
            # else
            #     echo
            # end

            # PRN add other analytics too? or instead?
        end


    end | column -t


end

abbr bs _brew_search_with_analytics
