

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
    set query $argv[1]

    # test with:
    #    _reload_config; _brew_search_with_analytics foo

    # ! PRN --desc --eval-all # option? (below for --cask too)
    # if pass --desc then not only are package names listed but their descriptions too => so I would have to split those out and keep descriptions probably so I can show them in my table too?

    set formula (brew search --formula $query)
    # set formula fox fop fio # hard code to test

    # split items (on " ") and trim \n on last item with gsub
    #   this builds an array of formula names that can be used below with IN operator to match on analytics by formula name
    set _array (echo $formula | jq -R -s -c 'split(" ") |  map(select(length > 0) | gsub("\n$"; ""))')
    begin
        echo FORMULA\tRANK\tINSTALLS\tPERCENT # header

        _brew_analytics_formula_annual | jq -r --argjson formula $_array '.items[] | select(.formula | IN($formula[])) | [.formula, .number, .count, .percent] | @tsv '

    end | column -t
    echo # blank line

    set cask (brew search --cask $query)
    set _array (echo $cask | jq -R -s -c 'split(" ") |  map(select(length > 0) | gsub("\n$"; ""))')
    begin
        echo CASK\tRANK\tINSTALLS\tPERCENT # header

        _brew_analytics_cask_annual | jq -r --argjson cask $_array '.items[] | select(.cask | IN($cask[])) | [.cask, .number, .count, .percent] | @tsv '

    end | column -t


end

ealias bs="_brew_search_with_analytics"