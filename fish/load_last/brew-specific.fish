

# PURPOSE:
#    combine `brew search foo` with analytics information to show install counts to gauge which packages are more popular (i.e. possibly better supported)

# FYI analytics: https://formulae.brew.sh/analytics/ (click through to find json files with current data)

# cache for duration of current shell session (instance)
#   -u => don't create file (dry-run)
#   just want the file name at this point
set tmp_formula_json (mktemp -u)
set tmp_cask_json (mktemp -u)

function _brew_analytics_formula_annual
    if ! test -e $tmp_formula_json
        curl -fsSL https://formulae.brew.sh/api/analytics/install/365d.json >$tmp_formula_json
    end
    cat $tmp_formula_json
end

function _brew_analytics_cask_annual
    if ! test -e $tmp_cask_json
        curl -fsSL https://formulae.brew.sh/api/analytics/cask-install/365d.json >$tmp_cask_json
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
        echo FORMULA\tRANK\tINSTALLS\tPERCENT\tSTARS\tFORKS # header

        # sample analytics record: {"number":325,"formula":"minikube","count":"131,246","percent":"0.06"}
        set analytics_records (_brew_analytics_formula_annual | jq -r --argjson formulae_names $_formulae_names_array_json '.items[] | select(.formula | IN($formulae_names[])) | [.formula, .number, .count, .percent] | @tsv ')
        # loop over each record so I can append columns:
        for record in $analytics_records
            set formula (echo $record | awk '{print $1}')
            echo -n $record

            if test -z $_flag_stars
                echo
                continue
            end

            set repo_url (brew info --formula $formula --json | jq '.[].urls.head | .url' -r)
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
        echo CASK\tRANK\tINSTALLS\tPERCENT # header

        _brew_analytics_cask_annual | jq -r --argjson cask_names $_casks_names_array_json '.items[] | select(.cask | IN($cask_names[])) | [.cask, .number, .count, .percent] | @tsv '
        # TODO impl stars/forks for casks too
    end | column -t


end

abbr bs _brew_search_with_analytics
