# pass an option (key) filter => 0 or more matching option names and details of each!
abbr aclsn "_ansible-config_options_name_contains"
function _ansible-config_options_name_contains
    set -l filter $argv
    command ansible-config list | yq "with_entries(select(.key | test(\"(?i).*$filter.*\")))"
end
abbr aclsd "_ansible-config_option_details_contains"
function _ansible-config_option_details_contains
    # TODO verify works in fish
    set -l key $1
    command ansible-config list | yq "with_entries(select(.. | has(\"$key\")))"
end
